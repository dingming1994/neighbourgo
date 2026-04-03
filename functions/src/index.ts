import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import Stripe from "stripe";

admin.initializeApp();
const db      = admin.firestore();
const storage = admin.storage();

// ─────────────────────────────────────────────────────────────────────────────
// Config (set via:  firebase functions:config:set stripe.secret="sk_live_...")
// ─────────────────────────────────────────────────────────────────────────────
const stripeSecret  = functions.config().stripe?.secret  ?? process.env.STRIPE_SECRET  ?? "";
const stripeWebhook = functions.config().stripe?.webhook ?? process.env.STRIPE_WEBHOOK ?? "";
const stripe        = new Stripe(stripeSecret, { apiVersion: "2024-06-20" });

// ─────────────────────────────────────────────────────────────────────────────
// 1. onCreate: Initialise new user document
// ─────────────────────────────────────────────────────────────────────────────
export const onUserCreate = functions
  .region("asia-southeast1")
  .auth.user()
  .onCreate(async (user) => {
    const now = FieldValue.serverTimestamp();
    await db.collection("users").doc(user.uid).set(
      {
        uid:                user.uid,
        phone:              user.phoneNumber ?? "",
        email:              user.email ?? null,
        role:               "poster",
        badges:             ["phoneVerified"],
        completenessScore:  10,
        stats: {
          completedTasks: 0,
          avgRating:      0.0,
          totalReviews:   0,
          repeatHires:    0,
          earningsTotal:  0.0,
        },
        isOnline:           true,
        isProfileComplete:  false,
        isDeactivated:      false,
        createdAt:          now,
        lastActiveAt:       now,
      },
      { merge: true }
    );
    functions.logger.info(`User initialised: ${user.uid}`);
  });

// ─────────────────────────────────────────────────────────────────────────────
// 2. onCreate: When a new task is posted, notify nearby providers via FCM
// ─────────────────────────────────────────────────────────────────────────────
export const onTaskCreate = functions
  .region("asia-southeast1")
  .firestore.document("tasks/{taskId}")
  .onCreate(async (snap, ctx) => {
    const task     = snap.data();
    const taskId   = ctx.params.taskId;

    // Find providers in the same neighbourhood who offer this category
    const providers = await db
      .collection("users")
      .where("role",               "in",        ["provider", "both"])
      .where("serviceCategories",  "array-contains", task.categoryId)
      .where("neighbourhood",      "==",        task.neighbourhood ?? "")
      .where("isDeactivated",      "==",        false)
      .limit(50)
      .get();

    const tokens: string[] = [];
    providers.docs.forEach((doc) => {
      const fcmToken = doc.data().fcmToken;
      if (fcmToken) tokens.push(fcmToken);
    });

    if (tokens.length === 0) return;

    // Send FCM multicast
    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title: `New ${task.categoryId} task near you! 🏘️`,
        body:  `${task.title} — ${task.budgetDisplay ?? "S$" + task.budgetMin}`,
      },
      data: {
        type:   "new_task",
        taskId: taskId,
        screen: `/tasks/${taskId}`,
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    };

    const res = await admin.messaging().sendEachForMulticast(message);
    functions.logger.info(`Task notify: ${res.successCount}/${tokens.length} sent`, { taskId });
  });

// ─────────────────────────────────────────────────────────────────────────────
// 3. Bid accepted: Create Stripe PaymentIntent (escrow)
// ─────────────────────────────────────────────────────────────────────────────
export const createEscrowPayment = functions
  .region("asia-southeast1")
  .https.onCall(async (data, ctx) => {
    if (!ctx.auth) throw new functions.https.HttpsError("unauthenticated", "Login required");

    const { taskId, bidId, amount } = data as { taskId: string; bidId: string; amount: number };

    // Validate task belongs to caller
    const taskDoc = await db.collection("tasks").doc(taskId).get();
    if (!taskDoc.exists || taskDoc.data()?.posterId !== ctx.auth.uid) {
      throw new functions.https.HttpsError("permission-denied", "Not your task");
    }

    const amountCents = Math.round(amount * 100);  // SGD → cents

    // Create PaymentIntent with manual capture (funds held until we capture)
    const intent = await stripe.paymentIntents.create({
      amount:          amountCents,
      currency:        "sgd",
      capture_method:  "manual",   // escrow: capture later on completion
      metadata: {
        taskId,
        bidId,
        posterId:   ctx.auth.uid,
      },
      description: `NeighbourGo Escrow — Task ${taskId}`,
    });

    // Store intent ID on task
    await db.collection("tasks").doc(taskId).update({
      paymentIntentId: intent.id,
      isPaid:          false,
    });

    return { clientSecret: intent.client_secret };
  });

// ─────────────────────────────────────────────────────────────────────────────
// 4. Task completed: Capture escrow & pay out provider
// ─────────────────────────────────────────────────────────────────────────────
export const releaseEscrow = functions
  .region("asia-southeast1")
  .https.onCall(async (data, ctx) => {
    if (!ctx.auth) throw new functions.https.HttpsError("unauthenticated", "Login required");

    const { taskId } = data as { taskId: string };
    const taskDoc    = await db.collection("tasks").doc(taskId).get();
    const task       = taskDoc.data();

    if (!task) throw new functions.https.HttpsError("not-found", "Task not found");
    if (task.posterId !== ctx.auth.uid) {
      throw new functions.https.HttpsError("permission-denied", "Not your task");
    }
    if (task.isEscrowReleased) {
      throw new functions.https.HttpsError("already-exists", "Escrow already released");
    }

    // Capture the held PaymentIntent
    await stripe.paymentIntents.capture(task.paymentIntentId);

    // Calculate platform fee & provider payout
    const totalAmount      = task.agreedAmount ?? task.budgetMin;
    const platformFee      = parseFloat((totalAmount * 0.13).toFixed(2));
    const providerPayout   = parseFloat((totalAmount - platformFee).toFixed(2));

    // Update task
    await db.collection("tasks").doc(taskId).update({
      status:           "completed",
      isEscrowReleased: true,
      completedAt:      FieldValue.serverTimestamp(),
    });

    // Update provider earnings
    if (task.assignedProviderId) {
      await db.collection("users").doc(task.assignedProviderId).update({
        "stats.earningsTotal": FieldValue.increment(providerPayout),
        "stats.completedTasks": FieldValue.increment(1),
      });
    }

    // Notify provider
    const providerDoc = await db.collection("users").doc(task.assignedProviderId).get();
    const fcmToken    = providerDoc.data()?.fcmToken;
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: "Payment received! 💰",
          body:  `S$${providerPayout} for "${task.title}" is in your wallet.`,
        },
        data: { type: "payment_received", taskId },
      });
    }

    return { success: true, providerPayout };
  });

// ─────────────────────────────────────────────────────────────────────────────
// 5. Stripe Webhook (for payment status updates from Stripe)
// ─────────────────────────────────────────────────────────────────────────────
export const stripeWebhookHandler = functions
  .region("asia-southeast1")
  .https.onRequest(async (req, res) => {
    const sig  = req.headers["stripe-signature"] as string;
    let event: Stripe.Event;

    try {
      event = stripe.webhooks.constructEvent(req.rawBody, sig, stripeWebhook);
    } catch (err: any) {
      functions.logger.error("Webhook signature failed", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    if (event.type === "payment_intent.payment_failed") {
      const intent = event.data.object as Stripe.PaymentIntent;
      const taskId = intent.metadata.taskId;
      if (taskId) {
        await db.collection("tasks").doc(taskId).update({ isPaid: false, paymentError: intent.last_payment_error?.message });
      }
    }

    res.json({ received: true });
  });

// ─────────────────────────────────────────────────────────────────────────────
// 6. Calculate & update profile completeness score
// ─────────────────────────────────────────────────────────────────────────────
export const updateCompletenessScore = functions
  .region("asia-southeast1")
  .firestore.document("users/{uid}")
  .onUpdate(async (change, ctx) => {
    const data  = change.after.data();
    let   score = 0;

    if (data.displayName)                              score += 15;
    if (data.avatarUrl)                                score += 15;
    if (data.headline)                                 score += 10;
    if (data.bio)                                      score += 10;
    if (data.neighbourhood)                            score += 5;
    if ((data.photos ?? []).length > 0)                score += 15;
    if ((data.serviceCategories ?? []).length > 0)     score += 10;
    if ((data.skillTags ?? []).length > 0)             score += 5;
    if ((data.categoryShowcases ?? []).length > 0)     score += 10;
    if ((data.badges ?? []).includes("idVerified"))    score += 5;

    // Only update if changed to avoid infinite loop
    if (data.completenessScore !== score) {
      await change.after.ref.update({ completenessScore: score });
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// 7. After task completion: prompt for review
// ─────────────────────────────────────────────────────────────────────────────
export const onTaskComplete = functions
  .region("asia-southeast1")
  .firestore.document("tasks/{taskId}")
  .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after  = change.after.data();

    if (before.status === after.status) return;          // no status change
    if (after.status !== "completed")   return;          // only fire on completion

    const taskId = ctx.params.taskId;

    // Notify both parties to leave a review
    const posterDoc   = await db.collection("users").doc(after.posterId).get();
    const providerDoc = after.assignedProviderId
        ? await db.collection("users").doc(after.assignedProviderId).get()
        : null;

    const msgs = [];

    if (posterDoc.data()?.fcmToken) {
      msgs.push(admin.messaging().send({
        token: posterDoc.data()!.fcmToken,
        notification: { title: "How was it? ⭐", body: `Leave a review for ${after.assignedProviderName ?? "your provider"}` },
        data: { type: "review_prompt", taskId, role: "poster" },
      }));
    }

    if (providerDoc?.data()?.fcmToken) {
      msgs.push(admin.messaging().send({
        token: providerDoc!.data()!.fcmToken,
        notification: { title: "Task done! Leave a review ⭐", body: `Rate your experience with ${after.posterName ?? "the poster"}` },
        data: { type: "review_prompt", taskId, role: "provider" },
      }));
    }

    await Promise.all(msgs);
  });

// ─────────────────────────────────────────────────────────────────────────────
// 8. Update provider average rating after new review
// ─────────────────────────────────────────────────────────────────────────────
export const onReviewCreate = functions
  .region("asia-southeast1")
  .firestore.document("users/{uid}/reviews/{reviewId}")
  .onCreate(async (snap, ctx) => {
    const review = snap.data();
    const uid    = ctx.params.uid;

    // Recalculate average rating from all reviews
    const reviewsSnap = await db.collection("users").doc(uid).collection("reviews").get();
    const ratings     = reviewsSnap.docs.map((d) => d.data().rating as number);
    const avg         = ratings.reduce((a, b) => a + b, 0) / ratings.length;

    await db.collection("users").doc(uid).update({
      "stats.avgRating":   parseFloat(avg.toFixed(2)),
      "stats.totalReviews": ratings.length,
    });
  });
