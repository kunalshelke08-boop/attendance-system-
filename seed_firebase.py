"""
Firebase Seeding Script — AttendEase (v2 — uses auth tokens)
Creates Firestore profiles for already-created Firebase Auth accounts.

All 72 student + 7 teacher Auth accounts already exist.
This script signs in to each, gets an idToken, and writes the Firestore profile.
"""

import requests
import json
import time

# ─── Firebase Config ──────────────────────────────────────
API_KEY = "AIzaSyC3AZPfMlrfxfTxliJAMaVIwNKm6tMHvkY"
PROJECT_ID = "flutterdgoat"

FIREBASE_SIGNIN_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
FIRESTORE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

CLASS_ID = "IIOT-7"

# ─── Student Data ────────────────────────────────────────
STUDENTS = [
    (23017001, "SALONI UMESH GAWATE"),
    (23017002, "BHAGYASHREE HARICHANDRA DHAKATE"),
    (23017003, "SHRUTI BHASKAR WAHANE"),
    (23017004, "ANUSHKA DNYANESHWAR BHOPE"),
    (23017005, "KUNAL PRAVIN SHELKE"),
    (23017006, "MOHIT PRAMOD UKUDDE"),
    (23017007, "BHUMIKA BHANUPRATAP DEOTARE"),
    (23017009, "VANASHREE NILESH BAREKAR"),
    (23017010, "ISHA SHIVKUMAR BAGHELE"),
    (23017012, "RUGVED NARENDRA PARDHY"),
    (23017013, "TEJAS SANJAY DUNEDAR"),
    (23017014, "SWATI TILAKCHAND CHHANIKAR"),
    (23017015, "PRATHAM VINOD CHAKOLE"),
    (23017016, "ARTHIK NASHIK CHAWARE"),
    (23017017, "BHUMIKA VIKAS SONTAKKE"),
    (23017018, "PARAG MANOJ BHAGAT"),
    (23017019, "TRUPTI PRAMOD THAWKAR"),
    (23017020, "SAANCHI BHARAT KAMBLE"),
    (23017021, "TANUSHREE SANJAY NAGESHWAR"),
    (23017023, "ACHAL AMOL DIWASE"),
    (23017024, "SHRAVANI SUBHASH THAKRE"),
    (23017026, "DHANASHRI RAVINDRA MATE"),
    (23017027, "SUVIDHA VIJAY KANTODE"),
    (23017028, "SANSKRUTI MANOJ BINEKAR"),
    (23017029, "SHARVARI GYANDEO PACHARE"),
    (23017030, "JANVI VILAS BHOYAR"),
    (23017031, "CHINMAI RAMESH MALAPOLU"),
    (23017032, "ANSHUL PRAVIN KAKDE"),
    (23017033, "SARANSHI SUNIL NANDANWAR"),
    (23017034, "VED AKASH AMTE"),
    (23017035, "SAMRUDDHI SARANG NERKAR"),
    (23017036, "VEDANTI RAVINDRA BHAYDE"),
    (23017037, "CHINMAY PRAFUL WADETTIWAR"),
    (23017038, "ALPA ANIRUDDHA PANDE"),
    (23017040, "ARYA RAJENDRA DHOTE"),
    (23017041, "RIYA RAVINDRA BELEKAR"),
    (23017042, "OM PRAVIN MISAL"),
    (23017043, "LAXMIKANT HEMRAJ BHOSKAR"),
    (23017045, "GAURAV PRAKASH KOSARE"),
    (23017046, "NIKUNJ SANJAY PATIL"),
    (23017047, "TANAY DEVENDRA RAUT"),
    (23017048, "SWAYAM PRAKASH KUKDE"),
    (23017049, "SHRAVANI DEVIDAS JOSHI"),
    (23017050, "SEJAL ASHOK SAHARKAR"),
    (23017051, "AVINASH SHRIKRUSHNA WANKHADE"),
    (23017052, "MAYANK MANISH KENE"),
    (23017053, "LAUKIK PRAKASH CHIVHANE"),
    (23017054, "OMKAR RAVINDRA KULKARNI"),
    (23017055, "VIBHANSHU UMESH MESHRAM"),
    (23017056, "ADITYA SACHIN LIKHITKAR"),
    (23017057, "SHUBHAM NITIN KULKARNI"),
    (23017058, "AARYAN NILESH VITALKAR"),
    (23017059, "DEEPANSHU SUNIL DHAKITE"),
    (23017060, "RUDRA ATUL DAHIKAR"),
    (23017062, "PRANVATI VINAY LANJWAR"),
    (23017063, "SHREYA MORESHWAR SATHAWANE"),
    (23017064, "ABOLI AJAYRAO WATKAR"),
    (23017065, "AYUSH VIJAY NIMJE"),
    (23017066, "OMSAIL VILAS RAJURKAR"),
    (24109001, "AAMOD KALEY"),
    (24109002, "ANSH UKEY"),
    (24109003, "DIVYA BURRIWAR"),
    (24109004, "ABHISHEK RAUT"),
    (24109005, "MRUNALI GULHANE"),
    (24109006, "DISHANT MUNGLE"),
    (24109007, "SARVESH GOTMARE"),
    (24109008, "ABHIJEET SHINDE"),
    (22017021, "ARJUN DABHOLKAR"),
    (22017033, "YASH CHIMANTRAWAR"),
    (22017041, "SRUSHTI BHAGWAT"),
    (22017061, "SUBHOJEET GUPTA"),
    (23117001, "RUSHIKESH DHOTE"),
]

TEACHERS = [
    ("cc",       "Cloud Computing",         "CC Teacher"),
    ("mdmv",     "MDM-V",                   "MDM-V Teacher"),
    ("sp",       "Signal Processing",       "SP Teacher"),
    ("pe3",      "PE-III",                  "PE-III Teacher"),
    ("iiot",     "II&I4.0 / IIOT Lab",      "IIOT Teacher"),
    ("project2", "PROJECT-II",              "Project-II Teacher"),
    ("mentor",   "Mentoring",               "Mentor"),
]


def title_case_name(name):
    return " ".join(w.capitalize() for w in name.strip().split())


def sign_in(email, password):
    """Sign in and return (localId, idToken) or (None, None)."""
    resp = requests.post(FIREBASE_SIGNIN_URL, json={
        "email": email,
        "password": password,
        "returnSecureToken": True,
    })
    data = resp.json()
    if resp.status_code == 200:
        return data["localId"], data["idToken"]
    else:
        msg = data.get("error", {}).get("message", "Unknown")
        print(f"  [SIGN-IN FAIL] {email} - {msg}")
        return None, None


def write_firestore_profile(uid, id_token, user_data):
    """Write user profile to Firestore using the authenticated user's token."""
    fields = {}
    for key, val in user_data.items():
        if isinstance(val, bool):
            fields[key] = {"booleanValue": val}
        elif isinstance(val, str):
            fields[key] = {"stringValue": val}

    fields["createdAt"] = {"timestampValue": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}

    resp = requests.patch(
        f"{FIRESTORE_URL}/users/{uid}",
        json={"fields": fields},
        headers={"Authorization": f"Bearer {id_token}"},
    )

    if resp.status_code in (200, 201):
        return True
    else:
        err = resp.json().get("error", {}).get("message", resp.text[:150])
        print(f"  [FIRESTORE FAIL] {err}")
        return False


def seed_students():
    print("=" * 60)
    print("  WRITING STUDENT FIRESTORE PROFILES")
    print("=" * 60)

    success, failed = 0, 0

    for uid_num, raw_name in STUDENTS:
        uid_str = str(uid_num)
        email = f"{uid_str}@svpcet.in"
        password = f"{uid_str}@attend"
        name = title_case_name(raw_name)

        print(f"\n[{uid_str}] {name}")

        local_id, id_token = sign_in(email, password)
        if not local_id:
            failed += 1
            continue

        user_data = {
            "name": name,
            "email": email,
            "role": "student",
            "classId": CLASS_ID,
        }

        if write_firestore_profile(local_id, id_token, user_data):
            print(f"  [OK] Profile written")
            success += 1
        else:
            failed += 1

        time.sleep(0.2)

    print(f"\n{'=' * 40}")
    print(f"Students: {success} OK, {failed} failed")
    return success


def seed_teachers():
    print("\n" + "=" * 60)
    print("  WRITING TEACHER FIRESTORE PROFILES")
    print("=" * 60)

    success, failed = 0, 0

    for abbrev, subject, placeholder_name in TEACHERS:
        email = f"{abbrev}@svpcet.in"
        password = f"{abbrev}@teach2026"

        print(f"\n[{abbrev}] {subject}")

        local_id, id_token = sign_in(email, password)
        if not local_id:
            failed += 1
            continue

        user_data = {
            "name": placeholder_name,
            "email": email,
            "role": "teacher",
            "classId": CLASS_ID,
            "subject": subject,
            "needsNameSetup": "true",
        }

        if write_firestore_profile(local_id, id_token, user_data):
            print(f"  [OK] Profile written: {email}")
            success += 1
        else:
            failed += 1

        time.sleep(0.2)

    print(f"\n{'=' * 40}")
    print(f"Teachers: {success} OK, {failed} failed")
    return success


def main():
    print()
    print("=" * 50)
    print("  AttendEase - Firestore Profile Writer (v2)")
    print("  Signs in to each account & writes profile")
    print("=" * 50)
    print()

    students = seed_students()
    teachers = seed_teachers()

    print("\n" + "=" * 60)
    print(f"  DONE! {students + teachers} profiles written.")
    print("=" * 60)


if __name__ == "__main__":
    main()
