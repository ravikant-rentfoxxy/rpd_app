#!/usr/bin/env python3
"""Generate the RPD Flutter app feature guide PDF."""

from pathlib import Path

from fpdf import FPDF

OUT = Path(__file__).with_name("RPD_Flutter_App_Guide.pdf")
NAVY = (41, 22, 104)
ORANGE = (232, 130, 36)
INK = (27, 23, 64)
MUTED = (90, 86, 110)
LINE = (228, 220, 208)
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
        self.cell(0, 5, ascii("RPD Sangathan Field App  |  Flutter Feature Guide"), align="L")
        self.set_xy(-40, 3.5)
        self.cell(26, 5, f"Page {self.page_no()}", align="R")
        self.set_y(18)

    def footer(self):
        if self.page_no() == 1:
            return
        self.set_y(-12)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(*MUTED)
        self.cell(0, 6, ascii("Internal product documentation  |  Screen-wise fields and working"), align="C")

    def h1(self, text):
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
        if self.get_y() > 260:
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
        self.cell(28, 5, ascii(label))
        self.set_xy(x + 28, y)
        self.set_font("Helvetica", "", 9)
        self.set_text_color(*INK)
        self.multi_cell(self.w - self.r_margin - x - 28, 5, ascii(value))
        self.set_x(self.l_margin)

    def table(self, headers, rows, widths=None):
        if self.get_y() > 250:
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
            rh = max(5.6, 5.2 + 4.2 * max(0, max(heights) - 0.2))
            rh = min(rh, 22)
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


def screen(pdf: Guide, title, route, file, purpose, fields, working, access, api=None, offline=None):
    pdf.h2(title)
    pdf.kv("Route", route)
    pdf.kv("File", file)
    pdf.kv("Purpose", purpose)
    pdf.h3("Fields and controls")
    pdf.table(["Field / control", "Type", "Working"], fields, [52, 32, 96])
    pdf.h3("How it works")
    for line in working:
        pdf.bullet(line)
    pdf.ln(1)
    pdf.kv("Access", access)
    if api:
        pdf.kv("APIs", api)
    if offline:
        pdf.kv("Offline", offline)


def main():
    pdf = Guide(format="A4", unit="mm")
    pdf.set_auto_page_break(auto=True, margin=16)
    pdf.set_left_margin(14)
    pdf.set_right_margin(14)

    # Cover
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
    pdf.set_font("Helvetica", "B", 28)
    pdf.set_text_color(255, 255, 255)
    pdf.multi_cell(160, 12, "Flutter Field App\nFeature Guide")
    pdf.set_xy(24, 122)
    pdf.set_font("Helvetica", "", 12)
    pdf.set_text_color(230, 220, 255)
    pdf.multi_cell(160, 6, "Screen-wise documentation of features, fields,\nvalidation, APIs, access rules, and offline behaviour.")
    pdf.set_xy(24, 160)
    pdf.set_font("Helvetica", "", 10)
    pdf.set_text_color(200, 190, 230)
    pdf.multi_cell(160, 6, "Stack: Flutter  |  GetX  |  Hive  |  Dio\nPlatforms: Android and iOS\nLanguages: English, Hindi, Bhojpuri")
    pdf.set_xy(24, 250)
    pdf.set_font("Helvetica", "", 9)
    pdf.cell(0, 6, "Internal document  |  September 2026")

    # How the app works
    pdf.add_page()
    pdf.h1("1. How the app works")
    pdf.p(
        "RPD is a field membership app for karyakartas. A user signs in with a mobile OTP, "
        "completes a 3-step join form, then uses Home, Activity, Members, and More. "
        "The app talks to the RPD backend over HTTPS and keeps a local Hive cache so Home, posts, "
        "and drafts still appear when the phone is offline."
    )
    pdf.h3("Startup")
    pdf.bullet("Boot reads assets/env for API_BASE_URL. If missing, the API Settings screen opens.")
    pdf.bullet("If no access token exists, the user goes to Mobile login.")
    pdf.bullet("If a token exists, the app calls GET /auth/me. Success opens Home or Join. Failure signs the user out.")
    pdf.bullet("Expired tokens try POST /auth/refresh. If refresh fails, the session is cleared and login opens quietly.")
    pdf.h3("Sign-in")
    pdf.bullet("User enters a 10-digit Indian mobile (starts with 6-9). App sends POST /auth/otp/request on WhatsApp channel.")
    pdf.bullet("In development, OTP is 123456. The app does not prefill it.")
    pdf.bullet("POST /auth/otp/verify returns tokens (90 days) and the member profile. A DRAFT member is created if the number is new.")
    pdf.h3("Join (3 steps, then contribution)")
    pdf.bullet("Step 1 About you: full name, date of birth (age 18-120), gender, optional photo.")
    pdf.bullet("Step 2 Your details: state, district, assembly, optional pincode and address, pledge toggle.")
    pdf.bullet("Step 3 Consent: required membership consent plus optional WhatsApp updates. Submit calls POST /members/register.")
    pdf.bullet("A contribution dialog then asks Primary Member or Volunteer and saves POST /members/contribution.")
    pdf.bullet("Save & exit on steps 1-2 stores the draft in Hive and opens Home without finishing join.")
    pdf.h3("Verified vs unverified")
    pdf.bullet("Verified users (status VERIFIED, or Super Admin) can use Activity, create post, add member, and the membership card.")
    pdf.bullet("Unverified users can stay on Home, open More, view posts, and edit Profile. Gated actions send them back to Join/status.")
    pdf.h3("Super Admin")
    pdf.bullet("Member flag isSuperAdmin (or post SUPER_ADMIN) is treated as verified.")
    pdf.bullet("They can open every gated screen, see all region posts, and use Verification inbox for all areas.")
    pdf.h3("Member ID")
    pdf.bullet("Each member has a table row id (1, 2, 3...). The card and profile show it as RPD-1, RPD-2, and so on.")
    pdf.h3("Local storage (Hive)")
    pdf.p(
        "settings: locale, API URL, tokens. user: profile. draft: join form. booths: cached booths. "
        "region_posts: post list. sync_queue: pending photo posts and activities. "
        "Sign out clears tokens, profile, draft, posts, queue, recruits, activities, and tasks. Locale and API URL stay."
    )
    pdf.h3("Languages")
    pdf.p("EN, HI, and BHO. The dropdown is on Login, Home, Activity, Members, and More. Choice is saved in Hive.")

    # Architecture
    pdf.h1("2. App structure")
    pdf.table(
        ["Layer", "What it does"],
        [
            ["GetX routes", "Named screens in app_pages.dart. Shell holds Home, Activity, Members, More."],
            ["SessionController", "Auth, profile, home load, location, join/register, gates, post sync."],
            ["ApiClient", "Dio client. Adds Bearer token. Refreshes on 401. Signs out if refresh fails."],
            ["HiveService", "Offline cache and drafts."],
            ["Backend", "Express + Prisma + Postgres. Media in MinIO/S3."],
        ],
        [42, 138],
    )
    pdf.h3("Bottom navigation")
    pdf.table(
        ["Tab", "Opens", "Gated?"],
        [
            ["Home", "Dashboard", "No"],
            ["Activity", "Record meeting / griha / programme / training", "Yes — verified only"],
            ["Center FAB", "Create post", "Yes — verified only"],
            ["Members", "My recruits", "View open; Add member gated"],
            ["More", "Card, posts, tasks, meeting, language, sign out", "Card overlay gated"],
        ],
        [36, 92, 52],
    )

    # Screens
    pdf.add_page()
    pdf.h1("3. Screens — fields and working")

    screen(
        pdf,
        "3.1 Boot",
        "/  (Routes.boot)",
        "lib/features/boot/boot_view.dart",
        "Startup router. No user fields.",
        [
            ["Spinner", "Loading", "Waits while session is restored"],
        ],
        [
            "If API URL is missing, go to API Settings.",
            "If no token, go to Mobile login.",
            "If token is valid, go to Home (verified) or Join/status (unverified).",
            "If token is invalid, clear session and go to login.",
        ],
        "Everyone at launch",
        "GET /auth/me, POST /home/active",
        "Uses cached profile if the network call fails for a non-401 reason.",
    )

    screen(
        pdf,
        "3.2 Mobile login",
        "/mobile",
        "lib/features/auth/auth_views.dart",
        "Collect the mobile number and send OTP.",
        [
            ["Language", "Dropdown EN/HI/BHO", "Changes app language immediately"],
            ["Your mobile number", "Heading", "Screen title"],
            ["Help text", "Text", "Explains that a 6-digit code will be sent"],
            ["Mobile number", "Text +91, 10 digits", "Must match 6-9 then 9 digits"],
            ["Send code", "Button", "POST /auth/otp/request then opens OTP screen"],
            ["Terms line", "Footer", "Membership terms and privacy notice"],
        ],
        [
            "Invalid number shows: Enter a 10-digit Indian mobile number.",
            "A new number creates a DRAFT member after OTP verify.",
            "Changing the number later clears a previous join draft.",
        ],
        "Signed-out users",
        "POST /auth/otp/request  { mobile, channel: WHATSAPP }",
        "Needs network.",
    )

    screen(
        pdf,
        "3.3 OTP",
        "/otp",
        "lib/features/auth/auth_views.dart",
        "Enter the 6-digit code.",
        [
            ["Back", "Icon", "Return to mobile screen"],
            ["Enter the code", "Heading", ""],
            ["+91 number · change", "Link", "Goes back to change the number"],
            ["OTP boxes", "6 digits", "Continue enables at 6 characters"],
            ["Continue", "Button", "POST /auth/otp/verify; saves tokens and profile"],
            ["Resend / SMS", "Text", "Shown only; not wired to a new request"],
        ],
        [
            "Demo OTP is 123456 on the development API.",
            "On success: verified users open Home; new/draft users open Join or member status.",
            "Super Admin skips join and opens Home.",
        ],
        "After Send code",
        "POST /auth/otp/verify  { mobile, code }",
        "Needs network.",
    )

    screen(
        pdf,
        "3.4 Join step 1 — About you",
        "/join/personal",
        "lib/features/join/join_views.dart",
        "Personal details. Also used inside Member status when the application is still a draft.",
        [
            ["Save & exit", "App bar", "Saves draft to Hive and opens Home"],
            ["Step 1 of 3", "Progress", "Visual only"],
            ["Photo", "Circle + camera", "Optional. Camera or Gallery; upload POST /members/photo"],
            ["Full name", "Text", "Required, at least 2 characters"],
            ["Date of birth *", "Date picker DD-MM-YYYY", "Age must be 18 to 120"],
            ["Gender", "Dropdown", "Male / Female / Other"],
            ["Continue", "Button", "Validates, marks step 1 done, opens step 2"],
        ],
        [
            "Values are written to the Hive draft as the user types.",
            "Photo is optional. Tap the photo later to view it full screen.",
        ],
        "New or unverified members",
        "POST /members/photo (optional)",
        "Draft stays on the device. Photo upload needs network.",
    )

    screen(
        pdf,
        "3.5 Join step 2 — Your details",
        "/join/booth",
        "lib/features/join/join_views.dart",
        "Address and constituency.",
        [
            ["Back", "App bar", "Returns to step 1"],
            ["Save & exit", "App bar", "Opens Home with draft saved"],
            ["State *", "Dropdown", "GET /geo/states (union territories excluded)"],
            ["District *", "Dropdown", "Loads after state: GET /geo/districts"],
            ["Assembly constituency *", "Dropdown", "Loads after district; first booth is auto-assigned"],
            ["Pincode", "6 digits", "Optional; if filled must be 6 digits"],
            ["Address", "Text", "Optional"],
            ["Pledge / updates", "Checkbox", "Default on. Stored as pledgeUpdates"],
            ["Continue", "Button", "Opens Consent"],
        ],
        [
            "Back arrow uses Get.offNamed to personal so the stack stays clean.",
            "Assembly pick loads booths for that AC and stores the first booth id in the draft.",
        ],
        "Join flow",
        "GET /geo/states, /geo/districts, /geo/assemblies, GET /booths?assemblyId=",
        "Draft is local. Empty dropdowns if geo APIs fail.",
    )

    screen(
        pdf,
        "3.6 Join step 3 — Consent",
        "/join/consent",
        "lib/features/join/join_views.dart",
        "Legal consent and registration.",
        [
            ["What we collect, and why", "Read-only", "Name, mobile, DOB, address, booth, photograph"],
            ["I agree to the above", "Required checkbox", "Must be checked"],
            ["WhatsApp updates", "Optional checkbox", "whatsappOptIn"],
            ["Submit application", "Button", "POST /members/register then contribution dialog"],
        ],
        [
            "Sends fullName, dateOfBirth, gender, boothId or assemblyId, address, pincode, locale, consent version, WhatsApp flag.",
            "On success the member becomes VERIFIED and gets membership number RPD-{rowId}.",
            "Contribution dialog is shown next (Primary Member or Volunteer).",
        ],
        "Join flow",
        "POST /members/register",
        "Submit needs network.",
    )

    screen(
        pdf,
        "3.7 Contribution dialog",
        "Modal after register",
        "lib/features/join/contribute_dialog.dart",
        "How the member wants to contribute.",
        [
            ["Close", "X", "Dismiss without saving"],
            ["Primary Member", "Radio", "Shows optional referral code / phone"],
            ["Volunteer", "Radio", "Shows Online/Offline and weekly hours 3-40"],
            ["Next", "Button", "POST /members/contribution then Home"],
        ],
        [
            "Primary Member: type PRIMARY_MEMBER, optional referralCode.",
            "Volunteer: type VOLUNTEER, volunteerMode ONLINE or OFFLINE, weeklyHours 3 to 40.",
        ],
        "After successful register",
        "POST /members/contribution",
        "Save needs network. Close always works.",
    )

    screen(
        pdf,
        "3.8 Member status",
        "/verification/status",
        "lib/features/verification/member_status_view.dart",
        "Resume join if draft/rejected; otherwise show application status.",
        [
            ["About you form", "Embedded", "Shown when DRAFT, REJECTED, or name is empty"],
            ["Status card", "Read-only", "Pending / Suspended / Withdrawn / Verified copy"],
            ["Check status", "Button", "GET /auth/me; opens Home if verified"],
            ["Sign out", "Button", "Logout dialog"],
        ],
        [
            "Unverified users land here when they tap a gated action.",
            "Pending copy explains the application is with the Mandal President.",
        ],
        "Unverified members",
        "GET /auth/me",
        "Shows cached status; Check status needs network.",
    )

    pdf.add_page()
    screen(
        pdf,
        "3.9 Home",
        "/shell tab Home",
        "lib/features/home/home_view.dart",
        "Dashboard after login.",
        [
            ["Avatar", "Tap", "Opens Profile"],
            ["Greeting + name", "Text", "Good morning/afternoon/evening + full name. Mobile is not shown."],
            ["Language pill", "Dropdown", "EN / HI / BHO"],
            ["Notifications bell", "Tap", "Opens Notifications (static list)"],
            ["Your community score", "Number /100", "From home stats or booth healthScore"],
            ["View booth", "Link", "Opens Booth health"],
            ["Queue banner", "If syncCount > 0", "Opens Sync queue"],
            ["Not verified banner", "If unverified", "Opens Join/status"],
            ["Tasks due", "Banner", "Opens Tasks"],
            ["Upcoming events", "Card + Join", "From GET /home"],
            ["Members added / Meetings held", "Stats", "From GET /home"],
            ["Mandal rank / points", "Card", "Leaderboard snapshot"],
            ["Recent videos", "Grid", "See more opens full list; tap opens YouTube URL"],
            ["Recent blogs", "Rail", "See more opens full list"],
            ["Recent activity near you", "Rail", "From home nearby cards"],
            ["Last activity", "Card", "Opens Activity tab if verified"],
            ["Pull to refresh", "Gesture", "Reloads GET /home and pending posts"],
        ],
        [
            "Home loads GET /home on first open and after refresh.",
            "Unverified users can stay here after Save & exit.",
        ],
        "All signed-in users",
        "GET /home",
        "Shows last cached home payload.",
    )

    screen(
        pdf,
        "3.10 Home lists and video",
        "/home/videos, /home/blogs, /home/nearby, /home/events, /video",
        "lib/features/home/home_feed_list_view.dart, youtube_player_view.dart",
        "Full lists of Home sections.",
        [
            ["App bar title", "Text", "Section name"],
            ["Feed cards", "List", "Image, title, place/source"],
            ["Join", "Button on events", "UI only from cached home data"],
        ],
        [
            "Lists reuse SessionController.home. No extra API.",
            "/video embeds youtube.com/embed/{id}. Home currently opens the external URL instead.",
        ],
        "All signed-in users",
        "None (cached /home)",
        "Uses last Home load.",
    )

    screen(
        pdf,
        "3.11 Activity hub",
        "/shell tab Activity",
        "lib/features/work/work_view.dart",
        "Choose what to record.",
        [
            ["Meeting", "Tile", "Opens activity capture with type MEETING"],
            ["Griha sampark", "Tile", "Type GRIHA_SAMPARK"],
            ["Programme", "Tile", "Type PUBLIC_PROGRAMME"],
            ["Training", "Tile", "Type TRAINING"],
        ],
        [
            "Unverified users are sent to Join/status immediately.",
            "Add member and Something else were removed from this hub.",
        ],
        "Verified only",
        "None on this screen",
        "N/A",
    )

    screen(
        pdf,
        "3.12 Activity capture",
        "/activity/details",
        "lib/features/activity/activity_views.dart",
        "Record an activity with photos and place.",
        [
            ["Purpose", "Read-only", "Selected activity type"],
            ["Add photos", "Camera / Gallery", "At least one photo required"],
            ["Time", "Read-only", "Captured now"],
            ["Location", "Lat/long or retry", "Uses device GPS; tap to retry"],
            ["Place name", "Text", "Village, school or landmark; at least 2 characters"],
            ["Submit", "Button", "POST /activities if online; else Hive + sync queue"],
        ],
        [
            "On success the Activity saved screen shows queue and pending points.",
            "Confirm and Rejected screens exist as older/demo routes.",
        ],
        "Verified only",
        "POST /activities",
        "Saved locally with status SAVED_LOCAL and queued.",
    )

    screen(
        pdf,
        "3.13 Members — My recruits",
        "/shell tab Members",
        "lib/features/members/members_view.dart",
        "People this user added.",
        [
            ["Verified / Pending / Rejected", "Count chips", "From GET /members/recruits"],
            ["Add member", "Button", "Verified only; opens mobile check"],
            ["Recruit row", "Name, booth, status", "List item"],
        ],
        [
            "Add member step 1: 10-digit mobile, GET /members/check/{mobile}.",
            "If already a member, shows membership number and name.",
            "Step 2 Recruit consent: full name, DOB, gender, required agree, 6-digit OTP field (length checked locally), POST /members/recruit.",
        ],
        "View: all signed-in. Add: verified.",
        "GET /members/recruits, GET /members/check/:mobile, POST /members/recruit",
        "Shows last loaded list.",
    )

    screen(
        pdf,
        "3.14 More",
        "/shell tab More",
        "lib/features/more/more_view.dart",
        "Secondary destinations.",
        [
            ["Verification inbox", "Card", "Only Super Admin or office-bearer posts"],
            ["Posts in your region", "Card", "Opens post list"],
            ["Membership card", "Card", "Verified overlay; flip and share"],
            ["Booth health", "Card", "Score components for assigned booth"],
            ["My tasks", "Card", "GET /tasks grouped overdue / today / week"],
            ["Booth meeting", "Card", "GET /meetings; check-in is a placeholder"],
            ["Language", "Dropdown", "EN / HI / BHO"],
            ["Sign out", "Button", "Confirm dialog, then login"],
        ],
        [
            "Membership card is an overlay, not a full-page route.",
            "Card front: name, Member ID RPD-n, mobile, referral, post, area, valid thru.",
            "Card back: address, pincode, state, district, AC name, issued date. No AC on the front.",
        ],
        "Signed-in; card and some actions gated",
        "Depends on destination",
        "Card uses cached profile if refresh fails.",
    )

    screen(
        pdf,
        "3.15 Profile",
        "/profile",
        "lib/features/profile/profile_view.dart",
        "View and edit the signed-in member.",
        [
            ["Photo", "Tap", "Camera or Gallery; POST /members/photo"],
            ["Member ID", "Read-only", "RPD-{rowId}"],
            ["Mobile number", "Read-only", "Last 10 digits"],
            ["Full name", "Text", "Required, 2+ characters"],
            ["Date of birth *", "Date picker", "Age 18-120"],
            ["Gender", "Dropdown", "Male / Female / Other"],
            ["Address", "Text", "Optional"],
            ["Pincode", "6 digits", "Optional; 6 digits if filled"],
            ["State / District / Assembly *", "Cascading", "Same geo APIs as join"],
            ["Save changes", "Button", "PATCH /members/me"],
        ],
        [
            "Opened from the Home avatar. Not verification-gated.",
            "RefreshMe runs on open so Super Admin and new IDs appear after re-login.",
        ],
        "All signed-in users",
        "GET /auth/me, geo APIs, PATCH /members/me, POST /members/photo",
        "Display works from cache; save needs network.",
    )

    screen(
        pdf,
        "3.16 Region posts",
        "/posts  and  /posts/create  and  /posts/video",
        "lib/features/post/post_views.dart",
        "Share photo, audio, or video with the region.",
        [
            ["My posts / Other posts", "Tabs", "Split by authorId and mobile"],
            ["Post card media", "Image / audio / video thumb", "Video shows thumbnail + play icon; tap opens player"],
            ["Description", "Text under media", "Optional"],
            ["Author · time", "Footer", "Name and relative time only"],
            ["Create FAB", "Orange post icon", "Verified only"],
            ["Photo / Audio / Video", "Tabs on create", "Photo works offline; audio/video need network"],
            ["Camera / Gallery or Record / Upload", "Source cards", "Horizontal; Replace keeps current media until a new file is picked"],
            ["Description (optional)", "Growing text field", "Max 2000 on API"],
            ["Post update", "Button", "Uploads multipart file + mediaType IMAGE|VIDEO|AUDIO"],
        ],
        [
            "Video: a JPEG thumbnail is generated on the phone and sent as field thumbnail. Stored as thumbnail_key.",
            "Photo offline: saved in Hive as pending REGION_POST and uploaded later from Sync or Home load.",
            "List does not start VideoPlayer on every card.",
        ],
        "View: all. Create: verified.",
        "GET /posts, POST /posts (multipart)",
        "List from Hive. Photo compose offline. Audio/video blocked offline.",
    )

    screen(
        pdf,
        "3.17 Verification inbox",
        "/verification",
        "lib/features/verification/inbox_view.dart",
        "Office bearers accept pending activities.",
        [
            ["To check", "App bar", ""],
            ["Activity card", "Type, booth, actor", "From GET /verification/inbox"],
            ["Accept", "Button", "POST /verification/{id}/accept"],
            ["Ask again", "Button", "Not wired"],
            ["Locked message", "Text", "Shown if the user has no verification post"],
        ],
        [
            "Allowed posts: Booth Adhyaksh and above, plus Super Admin.",
            "Super Admin sees all pending items, not only one mandal.",
        ],
        "Verification posts or Super Admin",
        "GET /verification/inbox, POST /verification/:id/accept",
        "Needs network to load.",
    )

    screen(
        pdf,
        "3.18 Other screens",
        "See table",
        "tasks, booth, meeting, sync, notifications, settings",
        "Supporting tools.",
        [
            ["My tasks /tasks", "List", "GET /tasks: overdue, today, this week"],
            ["Booth health /booth/health", "Scores", "GET /booths/{id}/health; Appoint Panna is not wired"],
            ["Booth meeting /meeting", "Agenda + invitees", "GET /meetings; Start check-in opens placeholder QR"],
            ["Check-in /meeting/checkin", "Placeholder", "No live QR scan"],
            ["Sync /sync", "Queue", "Try uploading now retries pending photo posts"],
            ["Notifications /notifications", "Static list", "Mark all read is local only"],
            ["API Settings /settings/api", "URL field", "Required if assets/env has no API_BASE_URL"],
            ["Error log /settings/logs", "Log list", "In-memory AppLog; no menu link"],
        ],
        [
            "Notifications and meeting check-in are UI placeholders.",
            "Sync queue also appears as a Home banner when items are waiting.",
        ],
        "Signed-in unless noted",
        "See field column",
        "Queue and logs are local.",
    )

    pdf.add_page()
    pdf.h1("4. Access matrix")
    pdf.table(
        ["Feature", "Unverified", "Verified member", "Super Admin / office bearer"],
        [
            ["Home", "Yes", "Yes", "Yes"],
            ["Save & exit join", "Yes", "n/a", "n/a"],
            ["Activity tab / capture", "No — sent to join", "Yes", "Yes"],
            ["Create post FAB", "No", "Yes", "Yes"],
            ["View region posts", "Yes", "Yes", "Yes (all posts)"],
            ["Add member", "No", "Yes", "Yes"],
            ["Membership card", "No", "Yes", "Yes"],
            ["Profile", "Yes", "Yes", "Yes"],
            ["Verification inbox", "No", "Only listed posts", "Yes, all areas"],
            ["Tasks / meeting / booth", "Yes", "Yes", "Yes"],
        ],
        [48, 42, 40, 50],
    )
    pdf.p(
        "Office-bearer posts that can open Verification inbox: SUPER_ADMIN, BOOTH_ADHYAKSH, "
        "MANDAL_PRESIDENT, ASSEMBLY_IN_CHARGE, DISTRICT_SECRETARY, DISTRICT_GENERAL_SECRETARY, "
        "DISTRICT_PRESIDENT, REGIONAL_PRESIDENT, STATE_GENERAL_SECRETARY, STATE_PRESIDENT, "
        "NATIONAL_GENERAL_SECRETARY, NATIONAL_PRESIDENT."
    )

    pdf.h1("5. API map")
    pdf.table(
        ["Method", "Path", "Used from"],
        [
            ["POST", "/auth/otp/request", "Mobile login"],
            ["POST", "/auth/otp/verify", "OTP"],
            ["POST", "/auth/refresh", "ApiClient on 401"],
            ["GET", "/auth/me", "Boot, Profile, Card"],
            ["POST", "/home/active", "Boot"],
            ["GET", "/home", "Home"],
            ["GET", "/geo/states|districts|assemblies", "Join, Profile"],
            ["GET", "/booths", "Join auto-booth"],
            ["GET", "/booths/nearby", "Nearby booth helper"],
            ["GET", "/booths/{id}/health", "Booth health"],
            ["POST", "/members/register", "Consent submit"],
            ["POST", "/members/contribution", "Contribution dialog"],
            ["POST", "/members/photo", "Join/Profile photo"],
            ["PATCH", "/members/me", "Profile save"],
            ["GET", "/members/check/{mobile}", "Add member"],
            ["POST", "/members/recruit", "Recruit consent"],
            ["GET", "/members/recruits", "Members tab"],
            ["POST", "/activities", "Activity capture"],
            ["GET/POST", "/posts", "Region posts; video includes thumbnail"],
            ["GET", "/tasks", "Tasks"],
            ["GET", "/meetings", "Meeting"],
            ["GET", "/verification/inbox", "Inbox"],
            ["POST", "/verification/{id}/accept", "Accept activity"],
        ],
        [22, 78, 80],
    )

    pdf.h1("6. Typical journeys")
    pdf.h3("New karyakarta")
    pdf.bullet("Login with mobile + OTP 123456 (dev) → About you → Details → Consent → Contribution → Home.")
    pdf.bullet("Member ID on the card becomes RPD-n from the members table row.")
    pdf.h3("Unverified browsing")
    pdf.bullet("Save & exit after step 1 or 2 → Home with Not verified banner.")
    pdf.bullet("Tapping Activity, FAB, card, or Add member returns them to Join/status.")
    pdf.h3("Create a video post")
    pdf.bullet("Verified user → FAB → Video tab → Record or Upload (needs signal).")
    pdf.bullet("App builds a JPEG thumbnail, sends file + thumbnail + mediaType VIDEO.")
    pdf.bullet("List shows thumbnail with a play icon. Tap opens the in-app player.")
    pdf.h3("Create a photo post offline")
    pdf.bullet("Photo tab works without network. Post is stored in Hive and the sync queue.")
    pdf.bullet("When the phone is online, Home load or Sync → Try uploading now sends it.")
    pdf.h3("Super Admin")
    pdf.bullet("Sign out and sign in again after the flag is set so /auth/me returns isSuperAdmin.")
    pdf.bullet("Home and all tabs unlock. More shows Verification inbox. Posts list is not limited by district.")

    pdf.h1("7. Notes")
    pdf.bullet("Notifications and meeting QR check-in are placeholder UI.")
    pdf.bullet("Activity Confirm/Rejected routes are older demo screens.")
    pdf.bullet("Error log and YouTube player routes exist but are not linked from More/Home.")
    pdf.bullet("After a database wipe, leftover tokens cause a silent sign-out on the next launch.")
    pdf.p("This guide matches the Flutter app in rpd_app as of September 2026.")

    pdf.output(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
