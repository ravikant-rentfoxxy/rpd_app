#!/usr/bin/env python3
"""Generate the RPD backend database + app usage PDF."""

from pathlib import Path

from fpdf import FPDF

OUT = Path(__file__).resolve().parents[2] / "rpd_backend" / "RPD_Backend_DB_Guide.pdf"
NAVY = (41, 22, 104)
ORANGE = (232, 130, 36)
INK = (27, 23, 64)
MUTED = (90, 86, 110)
PAPER = (255, 255, 255)
CREAM = (251, 246, 238)


def ascii(text):
    cleaned = (
        str(text)
        .replace("\u2014", "-")
        .replace("\u2013", "-")
        .replace("\u2018", "'")
        .replace("\u2019", "'")
        .replace("\u201c", '"')
        .replace("\u201d", '"')
        .replace("\u2022", "-")
        .replace("\u00a0", " ")
        .replace("\u00b7", "|")
        .replace("\u2026", "...")
        .replace("\u2192", "->")
        .replace("\u2190", "<-")
    )
    return cleaned.encode("latin-1", "replace").decode("latin-1")


class Guide(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_fill_color(*NAVY)
        self.rect(0, 0, self.w, 12, "F")
        self.set_font("Helvetica", "B", 8)
        self.set_text_color(255, 255, 255)
        self.set_xy(14, 3.5)
        self.cell(0, 5, ascii("RPD Sangathan  |  Backend database and app usage"), align="L")
        self.set_xy(-40, 3.5)
        self.cell(26, 5, f"Page {self.page_no()}", align="R")
        self.set_y(18)

    def footer(self):
        if self.page_no() == 1:
            return
        self.set_y(-12)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(*MUTED)
        self.cell(0, 6, ascii("Internal document  |  Postgres tables mapped to Flutter screens"), align="C")

    def h1(self, text):
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "B", 16)
        self.set_text_color(*NAVY)
        self.multi_cell(0, 8, ascii(text))
        self.set_draw_color(*ORANGE)
        self.set_line_width(0.7)
        y = self.get_y()
        self.line(14, y + 1, 60, y + 1)
        self.ln(6)

    def h2(self, text):
        self.ln(2)
        if self.get_y() > 258:
            self.add_page()
        self.set_x(self.l_margin)
        self.set_fill_color(*NAVY)
        self.set_text_color(255, 255, 255)
        self.set_font("Helvetica", "B", 11)
        self.cell(0, 8, ascii(f"  {text}"), fill=True, new_x="LMARGIN", new_y="NEXT")
        self.ln(3)

    def h3(self, text):
        if self.get_y() > 268:
            self.add_page()
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(*ORANGE)
        self.multi_cell(0, 6, ascii(text))
        self.ln(1)

    def p(self, text):
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "", 9.5)
        self.set_text_color(*INK)
        self.multi_cell(0, 5, ascii(text))
        self.ln(2)

    def bullet(self, text):
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "", 9.5)
        self.set_text_color(*INK)
        self.cell(5, 5, "-")
        self.multi_cell(0, 5, ascii(text))
        self.set_x(self.l_margin)

    def kv(self, label, value):
        if self.get_y() > 272:
            self.add_page()
        x = self.l_margin
        y = self.get_y()
        self.set_xy(x, y)
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(*NAVY)
        self.cell(36, 5, ascii(label))
        self.set_xy(x + 36, y)
        self.set_font("Helvetica", "", 9)
        self.set_text_color(*INK)
        self.multi_cell(self.w - self.r_margin - x - 36, 5, ascii(value))
        self.set_x(self.l_margin)

    def table(self, headers, rows, widths=None):
        if self.get_y() > 248:
            self.add_page()
        self.set_x(self.l_margin)
        usable = self.w - self.l_margin - self.r_margin
        if widths is None:
            widths = [usable / len(headers)] * len(headers)
        self.set_font("Helvetica", "B", 8)
        self.set_fill_color(*NAVY)
        self.set_text_color(255, 255, 255)
        h = 6.2
        for i, head in enumerate(headers):
            self.cell(widths[i], h, ascii(f" {head}"), border=0, fill=True)
        self.ln(h)
        self.set_font("Helvetica", "", 8)
        fill = False
        for row in rows:
            heights = []
            for i, cell in enumerate(row):
                heights.append(self.get_string_width(ascii(cell)) / max(widths[i] - 3, 8))
            rh = max(5.6, 5.2 + 4.2 * max(0, max(heights) - 0.15))
            rh = min(rh, 24)
            if self.get_y() + rh > 280:
                self.add_page()
                self.set_font("Helvetica", "B", 8)
                self.set_fill_color(*NAVY)
                self.set_text_color(255, 255, 255)
                for i, head in enumerate(headers):
                    self.cell(widths[i], h, ascii(f" {head}"), border=0, fill=True)
                self.ln(h)
                self.set_font("Helvetica", "", 8)
            self.set_fill_color(*CREAM if fill else PAPER)
            self.set_text_color(*INK)
            y0 = self.get_y()
            x0 = self.l_margin
            for i, cell in enumerate(row):
                self.set_xy(x0, y0)
                self.multi_cell(widths[i], 4.6, ascii(f" {cell}"), border=0, fill=True)
                x0 += widths[i]
            self.set_y(y0 + rh)
            fill = not fill
        self.ln(3)


def table_block(pdf, title, db_name, purpose, columns, used):
    pdf.h2(f"{title}  ({db_name})")
    pdf.p(purpose)
    pdf.h3("Columns")
    pdf.table(["Column", "Type", "Meaning"], columns, [46, 38, 96])
    pdf.h3("How the app uses it")
    for line in used:
        pdf.bullet(line)
    pdf.ln(1)


def main():
    pdf = Guide(format="A4", unit="mm")
    pdf.set_auto_page_break(auto=True, margin=16)
    pdf.set_left_margin(14)
    pdf.set_right_margin(14)

    pdf.add_page()
    pdf.set_fill_color(*NAVY)
    pdf.rect(0, 0, pdf.w, pdf.h, "F")
    pdf.set_fill_color(*ORANGE)
    pdf.rect(0, 0, 8, pdf.h, "F")
    pdf.set_xy(24, 70)
    pdf.set_font("Helvetica", "B", 13)
    pdf.set_text_color(*ORANGE)
    pdf.cell(0, 8, "RPD SANGATHAN")
    pdf.set_xy(24, 84)
    pdf.set_font("Helvetica", "B", 26)
    pdf.set_text_color(255, 255, 255)
    pdf.multi_cell(160, 12, "Backend Database Guide")
    pdf.set_xy(24, 122)
    pdf.set_font("Helvetica", "", 12)
    pdf.set_text_color(230, 220, 255)
    pdf.multi_cell(
        160,
        6,
        "Postgres tables, columns, and how the Flutter app\nreads and writes each one through the API.",
    )
    pdf.set_xy(24, 160)
    pdf.set_font("Helvetica", "", 10)
    pdf.set_text_color(200, 190, 230)
    pdf.multi_cell(
        160,
        6,
        "Stack: Express  |  Prisma  |  PostgreSQL  |  MinIO/S3\nApp: Flutter GetX + Hive cache\nSchema source: prisma/schema.prisma",
    )
    pdf.set_xy(24, 250)
    pdf.set_font("Helvetica", "", 9)
    pdf.cell(0, 6, "Internal document  |  September 2026")

    pdf.add_page()
    pdf.h1("1. How data reaches the app")
    pdf.p(
        "The Flutter app never talks to Postgres directly. It calls /api/v1/* on the Express API. "
        "Prisma maps tables to TypeScript models. The API serializes JSON. Hive on the phone caches "
        "the member profile, booths, region posts, and a sync queue."
    )
    pdf.h3("Path")
    pdf.bullet("Phone UI -> ApiClient (Dio) -> Express route -> Prisma -> PostgreSQL")
    pdf.bullet("Photos, audio, video files go to MinIO/S3. The database stores only the object key.")
    pdf.bullet("The app builds a public URL as /api/v1/media/{key} from photoUrl, mediaKey, thumbnailKey.")
    pdf.h3("IDs")
    pdf.bullet("Most primary keys are UUID. members.row_id is a serial integer 1, 2, 3...")
    pdf.bullet("The membership card and profile show RPD-{row_id}.")
    pdf.bullet("client_uuid on region_posts and activities is generated on the phone so retries do not create duplicates.")
    pdf.h3("Soft delete")
    pdf.bullet("members, booths, region_posts, activities use deleted_at. The API hides those rows.")

    pdf.h1("2. Hierarchy")
    pdf.p("India geography is stored as a tree. A member is pinned to one path on that tree.")
    pdf.table(
        ["Level", "Table", "App use"],
        [
            ["National / State / ...", "org_levels, org_posts", "Labels for party posts"],
            ["State", "states", "Join and Profile State dropdown"],
            ["Region / Zone", "regions", "Stored on member; not a join dropdown"],
            ["District", "districts", "Join and Profile District dropdown"],
            ["Assembly (AC)", "assembly_constituencies", "Join and Profile AC dropdown"],
            ["Mandal / Block", "mandals", "Assigned from booth; card area text"],
            ["Booth", "booths", "Auto-picked from AC; booth health and meetings"],
        ],
        [44, 56, 80],
    )
    pdf.p("Union territories are filtered out of GET /geo/states so the join list shows states only.")

    pdf.h1("3. Enums the app sees")
    pdf.table(
        ["Enum", "Values", "App"],
        [
            ["MemberStatus", "DRAFT PENDING VERIFIED REJECTED SUSPENDED WITHDRAWN", "Gates Home vs Join; status screen copy"],
            ["Gender", "MALE FEMALE OTHER UNDISCLOSED", "Join and Profile gender"],
            ["LocaleCode", "HI EN BHO", "Language of consent and UI locale"],
            ["PostType", "MEMBER, Panna, Booth Adhyaksh, Mandal to National posts", "JWT post; verification inbox access"],
            ["ContributionType", "PRIMARY_MEMBER VOLUNTEER DONATION", "Contribution dialog after register"],
            ["VolunteerMode", "ONLINE OFFLINE", "Volunteer option"],
            ["RegionPostMedia", "IMAGE AUDIO VIDEO", "Create post tab; list media tile"],
            ["ActivityType", "MEETING GRIHA_SAMPARK PUBLIC_PROGRAMME TRAINING ...", "Activity hub tiles"],
            ["ActivityStatus", "QUEUED UPLOADED PENDING_VERIFICATION VERIFIED ...", "Inbox Accept"],
            ["HealthBand", "STRONG ATTENTION WEAK", "Booth health pill"],
        ],
        [40, 78, 62],
    )

    pdf.add_page()
    pdf.h1("4. Tables")

    table_block(
        pdf,
        "members",
        "members",
        "One row per phone number. Created as DRAFT on first OTP. Filled by Join, Profile, and recruit.",
        [
            ["id", "UUID PK", "Internal id. JWT sub. Hive profile.id"],
            ["row_id", "SERIAL unique", "Shown as Member ID RPD-1, RPD-2"],
            ["membership_number", "varchar unique", "Set to RPD-{row_id} after create"],
            ["mobile_e164", "varchar unique", "Login number as +91XXXXXXXXXX. App shows last 10 digits"],
            ["mobile_hash", "varchar unique", "SHA-256 of mobile. Not sent to the app"],
            ["full_name", "varchar", "Home greeting, card, profile, post footer"],
            ["date_of_birth", "date", "Join and Profile DOB picker"],
            ["gender", "Gender", "Join and Profile dropdown"],
            ["locale", "LocaleCode", "Saved from app language on register"],
            ["status", "MemberStatus", "verified flag; unverified users stay on Home after Save and exit"],
            ["is_super_admin", "boolean", "Skips all gates; all posts; full verification inbox"],
            ["photo_url", "varchar", "S3 key. App loads /media/{key} on Home avatar, profile, card"],
            ["address, pincode", "varchar", "Join step 2, Profile, card back"],
            ["whatsapp_opt_in", "boolean", "Consent checkbox"],
            ["contribution_type", "enum", "Primary Member or Volunteer after register"],
            ["referral_code", "varchar", "Optional on contribution; shown as referral on card"],
            ["volunteer_mode, weekly_hours", "enum / int", "Volunteer fields"],
            ["valid_to", "date", "Card VALID THRU (2028-03-31 on register)"],
            ["state_id ... booth_id", "UUID FKs", "Geo path. Card area, post filters, booth health"],
            ["recruited_by_id", "UUID", "Members tab lists people this user added"],
            ["last_active_at", "timestamptz", "Updated by POST /home/active and GET /auth/me"],
        ],
        [
            "OTP verify: find by mobile or insert DRAFT with empty name.",
            "Join register: update name, DOB, geo, VERIFIED, then create card, MEMBER post, consents.",
            "GET /auth/me and serializeMember send this row to Hive profile.",
            "PATCH /members/me is Profile Save changes.",
            "Home avatar and name come from this cached profile.",
        ],
    )

    table_block(
        pdf,
        "member_posts",
        "member_posts",
        "Party office held by a member. One primary post is copied into the JWT as auth.post.",
        [
            ["member_id", "UUID FK", "Owner"],
            ["post", "PostType", "MEMBER by default on register"],
            ["booth_id ... state_id", "UUID", "Level the post applies to"],
            ["page_number", "int", "Panna page if used"],
            ["is_primary", "boolean", "serializeMember.post and login token"],
            ["ended_at", "timestamptz", "Null means current post"],
        ],
        [
            "Register and recruit insert post MEMBER if none exists.",
            "App uses post for verification inbox access and card post label.",
            "Super Admin does not need a post row; is_super_admin overrides.",
        ],
    )

    table_block(
        pdf,
        "membership_cards",
        "membership_cards",
        "One card per verified member. Created on register.",
        [
            ["member_id", "UUID unique", "Owner"],
            ["public_code", "varchar unique", "Same as membership_number (RPD-n)"],
            ["issued_at", "timestamptz", "Card back Issued on"],
            ["valid_to", "date", "Card front VALID THRU"],
        ],
        [
            "More -> Membership card overlay reads member.card from /auth/me.",
            "Share exports a PNG of the card faces. No extra table write.",
        ],
    )

    table_block(
        pdf,
        "otp_challenges",
        "otp_challenges",
        "One-time codes. Not shown in the app UI except as the 6 boxes the user types.",
        [
            ["mobile_e164", "varchar", "Number that requested the code"],
            ["code_hash", "varchar", "bcrypt of the OTP. Dev code is 123456"],
            ["channel", "WHATSAPP/SMS", "App always sends WHATSAPP"],
            ["purpose", "SIGN_IN / RECRUIT_CONSENT", "Login uses SIGN_IN"],
            ["attempts, max_attempts", "int", "Wrong code locks after 5 tries"],
            ["expires_at, consumed_at", "timestamptz", "TTL and one-time use"],
        ],
        [
            "Send code writes a row. Continue verifies hash then consumes it.",
            "Recruit consent OTP field in the app is length-only; it does not write this table yet.",
        ],
    )

    table_block(
        pdf,
        "refresh_tokens",
        "refresh_tokens",
        "Server-side session. Access JWT lasts 90 days; refresh rotates a hashed token.",
        [
            ["member_id", "UUID", "Session owner"],
            ["token_hash", "varchar unique", "Hash of the refresh JWT"],
            ["expires_at, revoked_at", "timestamptz", "Expiry or logout/rotate"],
            ["user_agent, ip_address", "varchar", "Audit of the device"],
        ],
        [
            "Hive stores access_token and refresh_token.",
            "401 on any API tries POST /auth/refresh. If the row is gone (DB wipe), the app signs out.",
        ],
    )

    pdf.add_page()
    table_block(
        pdf,
        "Geography tables",
        "states, regions, districts, assembly_constituencies, mandals",
        "Reference data for India. Seeded by upsert-india-geo and org hierarchy. Not edited in the app.",
        [
            ["id / code / name / name_hi", "UUID + text", "Dropdown labels"],
            ["Parent FKs", "UUID", "state -> region -> district -> AC -> mandal"],
            ["AC number", "int", "Assembly number in geo data"],
        ],
        [
            "GET /geo/states, /districts?stateId=, /assemblies?districtId= power Join step 2 and Profile.",
            "On register the API copies state, region, district, assembly, mandal, booth onto members.",
            "Card back shows stateName, districtName, assemblyName from those joins.",
        ],
    )

    table_block(
        pdf,
        "booths",
        "booths",
        "Polling booth / unit. Auto-assigned when the user picks an assembly.",
        [
            ["code, booth_number, part_number", "varchar", "Booth code on card and members list"],
            ["name, landmark, village, pincode", "varchar", "Place text"],
            ["voter_count, member_count", "int", "Health and stats"],
            ["latitude, longitude", "decimal", "Nearby booth search"],
            ["health_score, health_band", "int / enum", "Home community score fallback; Booth health"],
            ["last_activity_at", "timestamptz", "Updated when an activity is saved"],
        ],
        [
            "Join: GET /booths?assemblyId= picks the first booth and stores boothId in the draft.",
            "Home View booth and More Booth health call GET /booths/{id}/health.",
            "Recruit increments member_count.",
        ],
    )

    table_block(
        pdf,
        "booth_health_components",
        "booth_health_components",
        "Score bars on Booth health (committee, panna, members vs voters, activity).",
        [
            ["booth_id", "UUID", "Which booth"],
            ["key, label", "varchar", "Bar name"],
            ["score, max_score", "int", "14 of 20 style display"],
            ["detail", "varchar", "Subtitle under the bar"],
        ],
        [
            "GET /booths/{id}/health returns these rows. Home also uses them for community score.",
            "Appoint a Panna Pramukh on that screen does not write this table yet.",
        ],
    )

    table_block(
        pdf,
        "org_levels / org_posts",
        "org_levels, org_posts",
        "Catalog of National -> Mandal levels and allowed PostType titles.",
        [
            ["org_levels.code", "OrgLevelCode", "NATIONAL ... MANDAL"],
            ["org_posts.post / title", "PostType + text", "National President, Mandal President, ..."],
        ],
        [
            "GET /geo/org (if used) and seed data. App hardcodes the same list in org_hierarchy.dart.",
            "Does not store which person holds the post; that is member_posts.",
        ],
    )

    table_block(
        pdf,
        "consent_documents / member_consents",
        "consent_documents, member_consents",
        "Legal text and who accepted it.",
        [
            ["version, kind, locale", "text / enum", "2026.08 + MEMBERSHIP_REQUIRED or WHATSAPP_UPDATES"],
            ["title, body, is_current", "text / bool", "Consent screen copy (API can supply; app also has fallbacks)"],
            ["member_consents.accepted", "bool", "Join I agree and WhatsApp checkbox"],
            ["ip_address, user_agent", "varchar", "Audit on submit"],
        ],
        [
            "Register and recruit write MEMBERSHIP_REQUIRED. WhatsApp opt-in writes a second row.",
            "Join Consent screen shows the four paragraphs; submit requires the required checkbox.",
        ],
    )

    table_block(
        pdf,
        "region_posts",
        "region_posts",
        "Photo, audio, or video updates from Create post.",
        [
            ["client_uuid", "UUID unique", "Phone-generated id. Dedupes retry/sync"],
            ["author_id", "UUID", "My posts vs Other posts"],
            ["description", "varchar 2000", "Text under the media"],
            ["media_type", "IMAGE AUDIO VIDEO", "Which tile to render"],
            ["media_key", "varchar", "S3 key for the file"],
            ["thumbnail_key", "varchar null", "S3 JPEG for video; list shows thumb + play icon"],
            ["lat/lng, district_id, assembly_id, booth_id", "geo", "Region filter and label"],
            ["region_label", "varchar", "Village or booth name stored at post time"],
        ],
        [
            "POST /posts uploads file (and thumbnail for video) then inserts this row.",
            "GET /posts returns the member district/assembly plus own posts. Super Admin sees all.",
            "Hive region_posts caches the list. Offline photo posts wait in sync_queue then POST /posts.",
        ],
    )

    pdf.add_page()
    table_block(
        pdf,
        "activities + photos + attendees + reviews",
        "activities, activity_photos, activity_attendees, activity_reviews",
        "Field work captured from the Activity tab.",
        [
            ["client_uuid", "UUID", "Idempotent create via sync_idempotency"],
            ["actor_id, booth_id", "UUID", "Who did it and where"],
            ["type", "ActivityType", "Meeting, Griha, Programme, Training"],
            ["status", "ActivityStatus", "Starts queued; inbox Accept sets VERIFIED"],
            ["occurred_at, lat/lng", "time / geo", "Time and Location fields on capture"],
            ["notes", "text", "Place name / notes from the form"],
            ["photo_count, attendee_count", "int", "Inbox card counts"],
            ["activity_photos.storage_key", "varchar", "S3 key for each photo"],
            ["activity_reviews.decision", "status", "Accept writes VERIFIED + reviewer"],
        ],
        [
            "Activity capture POST /activities. Offline: Hive + sync queue first.",
            "Verification inbox GET /verification/inbox lists pending rows. Accept updates status and a review row.",
            "Home last activity uses the latest activity for the member.",
        ],
    )

    table_block(
        pdf,
        "meetings / invitees / check-ins",
        "meetings, meeting_invitees, meeting_check_ins",
        "Booth meeting screen. Check-in UI is still a placeholder.",
        [
            ["title, agenda, starts_at, venue", "text / time", "Meeting detail cards"],
            ["status", "SCHEDULED / IN_PROGRESS / CLOSED", "Countdown vs closed"],
            ["host_id, booth_id", "UUID", "Whose meeting"],
            ["invitees.post_label", "varchar", "Invited list role text"],
            ["check_ins.offline", "boolean", "Reserved for later QR sync"],
        ],
        [
            "More -> Booth meeting calls GET /meetings.",
            "Start check-in opens a QR placeholder; it does not write check_ins from the current UI.",
        ],
    )

    table_block(
        pdf,
        "tasks",
        "tasks",
        "Assigned work shown on Home tasks banner and My tasks.",
        [
            ["assignee_id, assigner_id", "UUID", "You / who assigned"],
            ["title, detail", "varchar", "Task card text"],
            ["status, priority", "enums", "Grouped as overdue, today, this week"],
            ["due_at, progress, target", "time / int", "Due date and progress"],
        ],
        [
            "GET /tasks for the signed-in assignee. GET /home also embeds tasksDueToday.",
            "The app does not currently mark tasks done from the UI.",
        ],
    )

    table_block(
        pdf,
        "point_rules / point_ledger",
        "point_rules, point_ledger",
        "Points for Home stats and mandal rank.",
        [
            ["point_rules.source / points", "enum / int", "e.g. MEMBER_VERIFIED = 10"],
            ["ledger.member_id, points, direction", "UUID / int / CREDIT|DEBIT", "Running score"],
            ["pending", "boolean", "True until activity is verified"],
            ["period_month", "date", "Monthly leaderboard window"],
        ],
        [
            "GET /home sums ledger for members added, meetings, points, mandal rank.",
            "Activity create may insert a pending credit. Inbox Accept can clear pending.",
            "Activity saved screen mentions points pending; that copy matches pending=true.",
        ],
    )

    table_block(
        pdf,
        "nearby_activity_cards",
        "nearby_activity_cards",
        "Static Home rail Recent activity near you (seeded titles and Unsplash images).",
        [
            ["title, place_label, image_url", "varchar", "Rail card"],
            ["sort_order", "int", "Display order"],
        ],
        [
            "GET /home includes these as nearbyActivities. Not the user's own GPS activities.",
        ],
    )

    table_block(
        pdf,
        "sync_idempotency / audit_logs",
        "sync_idempotency, audit_logs",
        "Server helpers. Little or no direct UI.",
        [
            ["sync client_uuid + route + response", "uuid / json", "Activity POST returns the same body on retry"],
            ["audit action / entity / metadata", "text / json", "Server audit trail"],
        ],
        [
            "The phone sync queue uses the same client UUID as region_posts and activities.",
            "Audit logs are not shown in the Flutter More menu.",
        ],
    )

    pdf.add_page()
    pdf.h1("5. Files in the bucket vs rows in the DB")
    pdf.p(
        "Bucket rpd-temp (MinIO). The database stores keys only. The API serves GET /api/v1/media/{key}."
    )
    pdf.table(
        ["S3 key pattern", "DB column", "App"],
        [
            ["members/{memberId}/{uuid}.jpg", "members.photo_url", "Avatar, profile, card photo"],
            ["posts/{memberId}/{uuid}.mp4|.m4a|.jpg", "region_posts.media_key", "Post media"],
            ["posts/{memberId}/{uuid}.jpg", "region_posts.thumbnail_key", "Video list thumbnail"],
            ["activity photo keys", "activity_photos.storage_key", "Activity photos"],
        ],
        [70, 50, 60],
    )

    pdf.h1("6. App cache (Hive) vs database")
    pdf.table(
        ["Hive box", "Mirrors"],
        [
            ["user.profile", "Serialized members + booth + card + post"],
            ["settings tokens", "refresh_tokens (hash on server, JWT on phone)"],
            ["draft", "Join fields before POST /members/register. Not a DB table"],
            ["booths", "Subset of booths from geo/nearby APIs"],
            ["region_posts", "region_posts list from GET /posts"],
            ["sync_queue", "Pending POST /posts or activities while offline"],
        ],
        [50, 130],
    )
    pdf.p("Sign out clears tokens, profile, draft, posts, and the queue. Locale and API URL stay.")

    pdf.h1("7. Write path by journey")
    pdf.h3("New login")
    pdf.bullet("otp_challenges insert -> members insert DRAFT -> refresh_tokens insert -> app stores JWTs.")
    pdf.h3("Finish join")
    pdf.bullet("members update VERIFIED + geo + RPD-n -> member_posts MEMBER -> membership_cards -> member_consents.")
    pdf.bullet("contribution dialog updates members.contribution_type (and volunteer fields).")
    pdf.h3("Create video post")
    pdf.bullet("Phone makes thumbnail -> S3 file + S3 thumb -> region_posts row with VIDEO + thumbnail_key.")
    pdf.bullet("List reads thumbnail_key. Play reads media_key.")
    pdf.h3("Record activity")
    pdf.bullet("activities + activity_photos + optional point_ledger pending -> booths.last_activity_at.")
    pdf.bullet("Office bearer Accept: activities.status VERIFIED + activity_reviews + ledger pending false.")
    pdf.h3("Add member")
    pdf.bullet("GET members by mobile. If new: members insert VERIFIED, recruited_by_id = you, booth member_count++.")

    pdf.h1("8. Screen to table map")
    pdf.table(
        ["Screen", "Reads", "Writes"],
        [
            ["Mobile / OTP", "members, otp_challenges", "otp_challenges, members DRAFT, refresh_tokens"],
            ["Join 1-3 / Consent", "geo tables, booths, consent_documents", "members, member_posts, cards, consents"],
            ["Contribution", "members", "members contribution columns"],
            ["Home", "members, tasks, ledger, booth health, nearby cards, activities", "members.last_active_at"],
            ["Profile", "members + geo", "members, photo object"],
            ["Membership card", "members + membership_cards + booth", "none"],
            ["Create / list posts", "region_posts + members author", "region_posts + S3"],
            ["Activity hub / capture", "booths", "activities, photos, ledger, booth last_activity"],
            ["Verification inbox", "activities + actor + booth", "activities, activity_reviews, ledger"],
            ["Members tab", "members where recruited_by_id", "members (recruit)"],
            ["Tasks / Meeting", "tasks / meetings", "mostly read; check-in not wired"],
            ["Booth health", "booths + booth_health_components", "none from app"],
        ],
        [48, 72, 60],
    )

    pdf.h1("9. Notes")
    pdf.bullet("After a DB wipe, refresh_tokens are gone so the app signs out on the next API call.")
    pdf.bullet("Super Admin is members.is_super_admin, not a PostType row.")
    pdf.bullet("Notifications screen is local dummy data; there is no notifications table.")
    pdf.p("Matches prisma/schema.prisma and the Flutter app as of September 2026.")

    pdf.output(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
