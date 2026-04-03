#!/usr/bin/env python3
"""
Seed NeighbourGo with realistic test data.
Creates accounts, posts tasks, submits bids, creates chats.
Uses Firebase REST API directly.
"""

import json
import requests
import time
import uuid
from datetime import datetime, timedelta

API_KEY = "AIzaSyD5D8VlR8I3yZKFZgH1G0FGNtKNgbHOLgA"
PROJECT_ID = "neighbourgo-sg"
AUTH_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}"
SIGNIN_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
FIRESTORE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

# ─────────────────────────────────────────────────────────────────────────────
# User profiles
# ─────────────────────────────────────────────────────────────────────────────
USERS = [
    # Providers
    {
        "email": "ben.cleaner@test.com", "password": "Test123456",
        "displayName": "Ben Lim", "role": "provider",
        "headline": "Professional cleaner with 5 years experience",
        "bio": "Specializing in deep cleaning for HDB flats and condos. I bring my own supplies and equipment. Serving Ang Mo Kio, Bishan, and Toa Payoh areas.",
        "neighbourhood": "Ang Mo Kio",
        "serviceCategories": ["cleaning"],
        "skillTags": ["#DeepClean", "#HDB", "#Eco-Friendly"],
        "serviceRates": {"cleaning": {"hourlyRate": 35}},
        "availableDays": ["Mon", "Tue", "Wed", "Thu", "Fri"],
        "availableHours": "9am - 6pm",
    },
    {
        "email": "sarah.tutor@test.com", "password": "Test123456",
        "displayName": "Sarah Chen", "role": "provider",
        "headline": "NIE-trained Math & Science tutor",
        "bio": "Former MOE teacher with 8 years of tutoring experience. Specializing in PSLE and O-Level Math and Science. Patient approach, proven results.",
        "neighbourhood": "Clementi",
        "serviceCategories": ["tutoring"],
        "skillTags": ["#PSLE", "#OLevel", "#Math", "#Science"],
        "serviceRates": {"tutoring": {"hourlyRate": 60}},
        "availableDays": ["Mon", "Wed", "Fri", "Sat"],
        "availableHours": "3pm - 9pm",
    },
    {
        "email": "raj.handyman@test.com", "password": "Test123456",
        "displayName": "Raj Kumar", "role": "provider",
        "headline": "All-round handyman — plumbing, electrical, furniture",
        "bio": "Licensed handyman with BCA certification. I fix everything from leaky taps to IKEA furniture assembly. Fast response, fair pricing.",
        "neighbourhood": "Tampines",
        "serviceCategories": ["handyman", "moving"],
        "skillTags": ["#Plumbing", "#Electrical", "#FurnitureAssembly", "#Painting"],
        "serviceRates": {"handyman": {"hourlyRate": 45}, "moving": {"hourlyRate": 55}},
        "availableDays": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        "availableHours": "8am - 8pm",
    },
    {
        "email": "mei.petcare@test.com", "password": "Test123456",
        "displayName": "Mei Ling", "role": "both",
        "headline": "Pet lover — walking, sitting, grooming",
        "bio": "Certified pet first-aider. I have 3 cats and 2 dogs of my own. Happy to walk, sit, or groom your furry friends in the Bedok/Tampines area.",
        "neighbourhood": "Bedok",
        "serviceCategories": ["pet_care", "errands"],
        "skillTags": ["#DogWalking", "#CatSitting", "#PetGrooming"],
        "serviceRates": {"pet_care": {"hourlyRate": 25}, "errands": {"hourlyRate": 15}},
        "availableDays": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        "availableHours": "7am - 10pm",
    },
    {
        "email": "james.multi@test.com", "password": "Test123456",
        "displayName": "James Tan", "role": "provider",
        "headline": "Queue standing & errands specialist",
        "bio": "I queue so you don't have to! From BTO launches to iPhone releases, I've got you covered. Also do grocery runs and parcel collection.",
        "neighbourhood": "Jurong East",
        "serviceCategories": ["queue_standing", "errands"],
        "skillTags": ["#QueueStanding", "#GroceryRun", "#ParcelCollection"],
        "serviceRates": {"queue_standing": {"hourlyRate": 20}, "errands": {"hourlyRate": 18}},
        "availableDays": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        "availableHours": "6am - 11pm",
    },
    # Clients
    {
        "email": "alice.client@test.com", "password": "Test123456",
        "displayName": "Alice Wong", "role": "poster",
        "headline": "Busy working mum",
        "bio": "Working professional and mother of two. Always looking for reliable help with housework and childcare.",
        "neighbourhood": "Ang Mo Kio",
        "serviceCategories": [],
        "skillTags": [],
    },
    {
        "email": "david.client@test.com", "password": "Test123456",
        "displayName": "David Ng", "role": "poster",
        "headline": "Tech worker, new to Singapore",
        "bio": "Just relocated to Singapore for work. Need help getting settled — from furniture assembly to finding a good tutor for my kid.",
        "neighbourhood": "Clementi",
        "serviceCategories": [],
        "skillTags": [],
    },
    {
        "email": "priya.client@test.com", "password": "Test123456",
        "displayName": "Priya Sharma", "role": "both",
        "headline": "Freelance designer & pet owner",
        "bio": "I work from home and have two golden retrievers. Sometimes need pet sitting when I travel for work.",
        "neighbourhood": "Bedok",
        "serviceCategories": ["admin_digital"],
        "skillTags": ["#GraphicDesign", "#WebDesign"],
        "serviceRates": {"admin_digital": {"hourlyRate": 50}},
        "availableDays": ["Mon", "Tue", "Wed", "Thu", "Fri"],
        "availableHours": "10am - 6pm",
    },
]

# ─────────────────────────────────────────────────────────────────────────────
# Tasks to post
# ─────────────────────────────────────────────────────────────────────────────
TASKS = [
    # Alice's tasks
    {
        "posterEmail": "alice.client@test.com",
        "title": "Deep clean 4-room HDB flat",
        "description": "Need a thorough deep cleaning for my 4-room HDB flat in Ang Mo Kio. Kitchen grease buildup, bathroom tiles need scrubbing, and all rooms need mopping. About 90 sqm. Please bring your own cleaning supplies.",
        "categoryId": "cleaning",
        "locationLabel": "Blk 456 Ang Mo Kio Ave 3 #08-123",
        "neighbourhood": "Ang Mo Kio",
        "budgetMin": 80, "budgetMax": 120,
        "urgency": "flexible",
    },
    {
        "posterEmail": "alice.client@test.com",
        "title": "P5 Math tutor needed — 2x/week",
        "description": "Looking for a patient Math tutor for my Primary 5 daughter. She's struggling with fractions and problem sums. Prefer someone who can come to our place in Ang Mo Kio, twice a week (Tue & Thu evenings).",
        "categoryId": "tutoring",
        "locationLabel": "Ang Mo Kio (home tuition)",
        "neighbourhood": "Ang Mo Kio",
        "budgetMin": 40, "budgetMax": 60,
        "urgency": "flexible",
    },
    {
        "posterEmail": "alice.client@test.com",
        "title": "Queue for iPhone 18 launch at Orchard",
        "description": "Need someone to queue at the Apple Store Orchard for the iPhone 18 launch on Saturday morning. You'd need to be there by 6am. I'll come around 10am to take over. Will provide breakfast money!",
        "categoryId": "queue_standing",
        "locationLabel": "Apple Store, ION Orchard",
        "neighbourhood": "Orchard",
        "budgetMin": 50, "budgetMax": 80,
        "urgency": "today",
    },
    # David's tasks
    {
        "posterEmail": "david.client@test.com",
        "title": "Assemble IKEA wardrobe + bookshelf",
        "description": "Just moved into my new place in Clementi. Have an IKEA PAX wardrobe and KALLAX bookshelf that need assembly. All parts and tools should be included in the boxes. Estimated 3-4 hours work.",
        "categoryId": "handyman",
        "locationLabel": "Blk 312 Clementi Ave 4 #05-67",
        "neighbourhood": "Clementi",
        "budgetMin": 100, "budgetMax": 180,
        "urgency": "asap",
    },
    {
        "posterEmail": "david.client@test.com",
        "title": "Help moving boxes from storage to new flat",
        "description": "I have about 20 boxes in a storage unit at Clementi that need to be moved to my new flat (same area, 10 min drive). Need someone with a van or large car. Boxes are mostly books and clothes, nothing too heavy.",
        "categoryId": "moving",
        "locationLabel": "Extra Space Storage, Clementi",
        "neighbourhood": "Clementi",
        "budgetMin": 80, "budgetMax": 150,
        "urgency": "today",
    },
    {
        "posterEmail": "david.client@test.com",
        "title": "Weekly grocery run from FairPrice",
        "description": "Looking for someone to do a weekly grocery run from FairPrice Clementi. I'll send a list every Sunday evening, and need delivery by Monday afternoon. Usually 2-3 bags worth.",
        "categoryId": "errands",
        "locationLabel": "FairPrice Finest, Clementi Mall",
        "neighbourhood": "Clementi",
        "budgetMin": 15, "budgetMax": 25,
        "urgency": "flexible",
    },
    # Priya's tasks
    {
        "posterEmail": "priya.client@test.com",
        "title": "Dog walking — 2 golden retrievers, daily",
        "description": "I have two golden retrievers (3 and 5 years old) who need daily walks while I'm in meetings. Looking for a regular dog walker in the Bedok area, weekdays 11am-12pm. They're friendly but strong pullers!",
        "categoryId": "pet_care",
        "locationLabel": "Blk 78 Bedok North St 4 #03-45",
        "neighbourhood": "Bedok",
        "budgetMin": 20, "budgetMax": 30,
        "urgency": "flexible",
    },
    {
        "posterEmail": "priya.client@test.com",
        "title": "Pet sitting for 3 days — 2 dogs",
        "description": "Traveling to KL for a design conference Fri-Sun. Need someone to stay at my place and take care of my two golden retrievers. They need walks 2x/day, feeding at 7am and 6pm. I'll prepare all food and supplies.",
        "categoryId": "pet_care",
        "locationLabel": "Bedok (my home)",
        "neighbourhood": "Bedok",
        "budgetMin": 60, "budgetMax": 100,
        "urgency": "today",
    },
    {
        "posterEmail": "priya.client@test.com",
        "title": "Fix leaking kitchen tap",
        "description": "Kitchen tap has been dripping for a week. Tried tightening it myself but no luck. It's a standard HDB kitchen mixer tap. Need someone who can diagnose and fix it quickly.",
        "categoryId": "handyman",
        "locationLabel": "Blk 78 Bedok North St 4 #03-45",
        "neighbourhood": "Bedok",
        "budgetMin": 40, "budgetMax": 70,
        "urgency": "asap",
    },
]

# ─────────────────────────────────────────────────────────────────────────────
# Bids (provider → task)
# ─────────────────────────────────────────────────────────────────────────────
BIDS = [
    # Multiple bids on Alice's cleaning task
    {"providerEmail": "ben.cleaner@test.com", "taskTitle": "Deep clean 4-room HDB flat",
     "amount": 95, "message": "Hi Alice! I specialise in HDB deep cleaning. 5 years experience, I bring all my own eco-friendly supplies. Can do it this weekend."},
    {"providerEmail": "mei.petcare@test.com", "taskTitle": "Deep clean 4-room HDB flat",
     "amount": 110, "message": "I can help with the cleaning! I'm very thorough and detail-oriented. Available any weekday."},

    # Bids on Alice's tutoring task
    {"providerEmail": "sarah.tutor@test.com", "taskTitle": "P5 Math tutor needed — 2x/week",
     "amount": 50, "message": "Hi! I'm an ex-MOE teacher specialising in PSLE Math. I have lots of experience with fractions and problem sums. Happy to do a free trial session first."},

    # Bids on Alice's queue task
    {"providerEmail": "james.multi@test.com", "taskTitle": "Queue for iPhone 18 launch at Orchard",
     "amount": 60, "message": "I'm a professional queuer! Done this 5 times before for various launches. I'll bring my camping chair and be there at 5:30am."},

    # Multiple bids on David's IKEA task
    {"providerEmail": "raj.handyman@test.com", "taskTitle": "Assemble IKEA wardrobe + bookshelf",
     "amount": 120, "message": "Hi David, I've assembled hundreds of IKEA pieces. PAX wardrobes are my specialty — usually takes me 2 hours. I have all my own tools."},
    {"providerEmail": "james.multi@test.com", "taskTitle": "Assemble IKEA wardrobe + bookshelf",
     "amount": 150, "message": "Can help with the assembly! I've done PAX before, should take about 3 hours total for both pieces."},

    # Bids on David's moving task
    {"providerEmail": "raj.handyman@test.com", "taskTitle": "Help moving boxes from storage to new flat",
     "amount": 100, "message": "I have a van! Can move all 20 boxes in one trip. Available this weekend. Will bring trolley and moving blankets."},

    # Bids on David's grocery task
    {"providerEmail": "james.multi@test.com", "taskTitle": "Weekly grocery run from FairPrice",
     "amount": 18, "message": "I do regular errands in the Clementi area. Happy to add a weekly grocery run to my route. I'm very reliable — been doing this for 2 years."},
    {"providerEmail": "mei.petcare@test.com", "taskTitle": "Weekly grocery run from FairPrice",
     "amount": 20, "message": "I can do this! I go to FairPrice regularly anyway. Will pick the freshest items for you."},

    # Multiple bids on Priya's dog walking
    {"providerEmail": "mei.petcare@test.com", "taskTitle": "Dog walking — 2 golden retrievers, daily",
     "amount": 25, "message": "I LOVE golden retrievers! I walk dogs daily in the Bedok area already. I'm a certified pet first-aider so your pups are in safe hands."},
    {"providerEmail": "james.multi@test.com", "taskTitle": "Dog walking — 2 golden retrievers, daily",
     "amount": 22, "message": "Happy to walk your dogs! I'm very active and can handle strong pullers. Available every weekday."},

    # Bids on Priya's pet sitting
    {"providerEmail": "mei.petcare@test.com", "taskTitle": "Pet sitting for 3 days — 2 dogs",
     "amount": 80, "message": "I'd love to pet sit your goldens! I have experience with large breeds and can stay at your place. I'll send photos and updates throughout the day."},

    # Bids on Priya's handyman task
    {"providerEmail": "raj.handyman@test.com", "taskTitle": "Fix leaking kitchen tap",
     "amount": 45, "message": "Leaky taps are my bread and butter! 90% of the time it's just a worn washer — quick 30min fix. I bring all spare parts."},
]

# ─────────────────────────────────────────────────────────────────────────────
# Execute seeding
# ─────────────────────────────────────────────────────────────────────────────
def create_user(user_data):
    """Create Firebase Auth user + Firestore profile."""
    # Create auth account
    resp = requests.post(AUTH_URL, json={
        "email": user_data["email"],
        "password": user_data["password"],
        "returnSecureToken": True,
    })
    if resp.status_code != 200:
        # Try sign in if already exists
        resp = requests.post(SIGNIN_URL, json={
            "email": user_data["email"],
            "password": user_data["password"],
            "returnSecureToken": True,
        })
    
    data = resp.json()
    uid = data.get("localId", "")
    token = data.get("idToken", "")
    
    if not uid:
        print(f"  FAILED: {user_data['email']} — {data.get('error', {}).get('message', 'unknown')}")
        return None, None
    
    # Create Firestore user doc
    user_doc = {
        "fields": {
            "uid": {"stringValue": uid},
            "phone": {"stringValue": ""},
            "email": {"stringValue": user_data["email"]},
            "displayName": {"stringValue": user_data["displayName"]},
            "role": {"stringValue": user_data["role"]},
            "headline": {"stringValue": user_data.get("headline", "")},
            "bio": {"stringValue": user_data.get("bio", "")},
            "neighbourhood": {"stringValue": user_data.get("neighbourhood", "")},
            "isProfileComplete": {"booleanValue": True},
            "isOnline": {"booleanValue": False},
            "isDeactivated": {"booleanValue": False},
            "completenessScore": {"integerValue": "70"},
            "serviceCategories": {"arrayValue": {"values": [{"stringValue": c} for c in user_data.get("serviceCategories", [])]}},
            "skillTags": {"arrayValue": {"values": [{"stringValue": t} for t in user_data.get("skillTags", [])]}},
            "availableDays": {"arrayValue": {"values": [{"stringValue": d} for d in user_data.get("availableDays", [])]}},
            "photos": {"arrayValue": {"values": []}},
            "badges": {"arrayValue": {"values": [{"stringValue": "phoneVerified"}]}},
            "categoryShowcases": {"arrayValue": {"values": []}},
            "createdAt": {"timestampValue": datetime.utcnow().isoformat() + "Z"},
            "lastActiveAt": {"timestampValue": datetime.utcnow().isoformat() + "Z"},
        }
    }
    
    if user_data.get("availableHours"):
        user_doc["fields"]["availableHours"] = {"stringValue": user_data["availableHours"]}
    
    if user_data.get("serviceRates"):
        rates = {}
        for cat, rate in user_data["serviceRates"].items():
            rates[cat] = {"mapValue": {"fields": {"hourlyRate": {"doubleValue": rate["hourlyRate"]}}}}
        user_doc["fields"]["serviceRates"] = {"mapValue": {"fields": rates}}
    
    # Write to Firestore
    url = f"{FIRESTORE_URL}/users/{uid}"
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.patch(url, json=user_doc, headers=headers)
    
    if resp.status_code == 200:
        print(f"  ✅ {user_data['displayName']} ({user_data['role']}) — {user_data['email']}")
    else:
        print(f"  ⚠️  {user_data['displayName']} — Firestore write: {resp.status_code}")
    
    return uid, token


def create_task(task_data, poster_uid, poster_token, poster_name):
    """Create a task in Firestore."""
    task_id = str(uuid.uuid4())
    
    task_doc = {
        "fields": {
            "id": {"stringValue": task_id},
            "posterId": {"stringValue": poster_uid},
            "posterName": {"stringValue": poster_name},
            "title": {"stringValue": task_data["title"]},
            "description": {"stringValue": task_data["description"]},
            "categoryId": {"stringValue": task_data["categoryId"]},
            "locationLabel": {"stringValue": task_data["locationLabel"]},
            "neighbourhood": {"stringValue": task_data["neighbourhood"]},
            "budgetMin": {"doubleValue": task_data["budgetMin"]},
            "currency": {"stringValue": "SGD"},
            "urgency": {"stringValue": task_data["urgency"]},
            "status": {"stringValue": "open"},
            "bidCount": {"integerValue": "0"},
            "viewCount": {"integerValue": "0"},
            "isPaid": {"booleanValue": False},
            "isEscrowReleased": {"booleanValue": False},
            "isDirectHire": {"booleanValue": False},
            "photoUrls": {"arrayValue": {"values": []}},
            "tags": {"arrayValue": {"values": []}},
            "createdAt": {"timestampValue": datetime.utcnow().isoformat() + "Z"},
            "updatedAt": {"timestampValue": datetime.utcnow().isoformat() + "Z"},
        }
    }
    
    if task_data.get("budgetMax"):
        task_doc["fields"]["budgetMax"] = {"doubleValue": task_data["budgetMax"]}
    
    url = f"{FIRESTORE_URL}/tasks/{task_id}"
    headers = {"Authorization": f"Bearer {poster_token}"}
    resp = requests.patch(url, json=task_doc, headers=headers)
    
    if resp.status_code == 200:
        print(f"  ✅ Task: {task_data['title'][:50]}")
    else:
        print(f"  ⚠️  Task failed: {resp.status_code} — {resp.text[:100]}")
    
    return task_id


def create_bid(task_id, task_title, provider_uid, provider_token, provider_name, amount, message):
    """Create a bid on a task."""
    bid_id = str(uuid.uuid4())
    
    bid_doc = {
        "fields": {
            "bidId": {"stringValue": bid_id},
            "taskId": {"stringValue": task_id},
            "providerId": {"stringValue": provider_uid},
            "providerName": {"stringValue": provider_name},
            "amount": {"doubleValue": amount},
            "message": {"stringValue": message},
            "status": {"stringValue": "pending"},
            "createdAt": {"timestampValue": datetime.utcnow().isoformat() + "Z"},
        }
    }
    
    url = f"{FIRESTORE_URL}/tasks/{task_id}/bids/{bid_id}"
    headers = {"Authorization": f"Bearer {provider_token}"}
    resp = requests.patch(url, json=bid_doc, headers=headers)
    
    if resp.status_code == 200:
        print(f"  ✅ Bid: {provider_name} → {task_title[:40]} (S${amount})")
    else:
        print(f"  ⚠️  Bid failed: {resp.status_code}")
    
    # Update bid count
    # (skip for now — would need PATCH with fieldTransform)


def main():
    print("=" * 60)
    print("  NeighbourGo Test Data Seeder")
    print("=" * 60)
    
    # Phase 1: Create users
    print("\n--- PHASE 1: Creating Users ---")
    user_map = {}  # email → (uid, token, name)
    
    for user in USERS:
        uid, token = create_user(user)
        if uid:
            user_map[user["email"]] = (uid, token, user["displayName"])
        time.sleep(0.3)
    
    # Phase 2: Create tasks
    print("\n--- PHASE 2: Posting Tasks ---")
    task_map = {}  # title → task_id
    
    for task in TASKS:
        poster = user_map.get(task["posterEmail"])
        if not poster:
            print(f"  SKIP: no user for {task['posterEmail']}")
            continue
        uid, token, name = poster
        task_id = create_task(task, uid, token, name)
        task_map[task["title"]] = task_id
        time.sleep(0.3)
    
    # Phase 3: Submit bids
    print("\n--- PHASE 3: Submitting Bids ---")
    for bid in BIDS:
        provider = user_map.get(bid["providerEmail"])
        task_id = task_map.get(bid["taskTitle"])
        if not provider or not task_id:
            print(f"  SKIP: missing data for bid")
            continue
        uid, token, name = provider
        create_bid(task_id, bid["taskTitle"], uid, token, name, bid["amount"], bid["message"])
        time.sleep(0.3)
    
    # Output summary
    print("\n" + "=" * 60)
    print("  SEED COMPLETE — Account Reference")
    print("=" * 60)
    print("\n  All passwords: Test123456\n")
    print(f"  {'Email':<30} {'Name':<18} {'Role':<10}")
    print(f"  {'-'*30} {'-'*18} {'-'*10}")
    for user in USERS:
        print(f"  {user['email']:<30} {user['displayName']:<18} {user['role']:<10}")
    
    print(f"\n  Tasks posted: {len(task_map)}")
    print(f"  Bids submitted: {len(BIDS)}")
    print()


if __name__ == "__main__":
    main()
