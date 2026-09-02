import 'package:get/get.dart';
import '../../features/boot/boot_view.dart';
import '../../features/activity/activity_views.dart';
import '../../features/auth/auth_views.dart';
import '../../features/booth/booth_health_view.dart';
import '../../features/card/membership_card_view.dart';
import '../../features/join/join_views.dart';
import '../../features/meeting/meeting_views.dart';
import '../../features/members/members_view.dart';
import '../../features/onboarding/language_view.dart';
import '../../features/settings/api_settings_view.dart';
import '../../features/settings/error_log_view.dart';
import '../../features/shell/shell_view.dart';
import '../../features/sync/sync_view.dart';
import '../../features/tasks/tasks_view.dart';
import '../../features/verification/inbox_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: Routes.boot, page: () => const BootView()),
    GetPage(name: Routes.language, page: () => const LanguageView()),
    GetPage(name: Routes.mobile, page: () => const MobileView()),
    GetPage(name: Routes.otp, page: () => const OtpView()),
    GetPage(name: Routes.personal, page: () => const PersonalView()),
    GetPage(name: Routes.boothSelect, page: () => const BoothSelectView()),
    GetPage(name: Routes.boothSearch, page: () => const BoothSearchView()),
    GetPage(name: Routes.consent, page: () => const ConsentView()),
    GetPage(name: Routes.shell, page: () => const ShellView()),
    GetPage(name: Routes.card, page: () => const MembershipCardView()),
    GetPage(name: Routes.activityDetails, page: () => const ActivityDetailsView()),
    GetPage(name: Routes.activityConfirm, page: () => const ActivityConfirmView()),
    GetPage(name: Routes.activitySaved, page: () => const ActivitySavedView()),
    GetPage(name: Routes.activityRejected, page: () => const ActivityRejectedView()),
    GetPage(name: Routes.addMember, page: () => const AddMemberView()),
    GetPage(name: Routes.recruitConsent, page: () => const RecruitConsentView()),
    GetPage(name: Routes.boothHealth, page: () => const BoothHealthView()),
    GetPage(name: Routes.meeting, page: () => const MeetingDetailView()),
    GetPage(name: Routes.checkIn, page: () => const CheckInView()),
    GetPage(name: Routes.tasks, page: () => const TasksView()),
    GetPage(name: Routes.sync, page: () => const SyncView()),
    GetPage(name: Routes.verification, page: () => const VerificationInboxView()),
    GetPage(name: Routes.apiSettings, page: () => const ApiSettingsView()),
    GetPage(name: Routes.errorLog, page: () => const ErrorLogView()),
  ];
}
