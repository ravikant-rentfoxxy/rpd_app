import 'package:get/get.dart';
import '../../features/boot/boot_view.dart';
import '../../features/activity/activity_views.dart';
import '../../features/work/work_view.dart';
import '../../features/auth/auth_views.dart';
import '../../features/district/district_health_view.dart';
import '../../features/card/membership_card_view.dart';
import '../../features/profile/profile_view.dart';
import '../../features/profile/profile_overview_view.dart';
import '../../features/home/home_feed_list_view.dart';
import '../../features/home/youtube_player_view.dart';
import '../../data/models/home_feed.dart';
import '../../features/session/session_controller.dart';
import '../../features/join/join_views.dart';
import '../../features/join/profile_basics_view.dart';
import '../../features/meeting/meeting_views.dart';
import '../../features/members/members_view.dart';
import '../../features/settings/api_settings_view.dart';
import '../../features/settings/error_log_view.dart';
import '../../features/shell/shell_view.dart';
import '../../features/sync/sync_view.dart';
import '../../features/tasks/create_task_view.dart';
import '../../features/tasks/tasks_view.dart';
import '../../features/notifications/notifications_view.dart';
import '../../features/verification/inbox_view.dart';
import '../../features/verification/member_status_view.dart';
import '../../features/post/post_views.dart';
import '../../features/post/post_detail_view.dart';
import '../../features/post/post_video_view.dart';
import '../../features/post/grievance_view.dart';
import '../../features/events/create_event_view.dart';
import '../../features/events/event_detail_view.dart';
import '../../features/engagement/engagement_play_view.dart';
import '../../features/activity_event/activity_event_play_view.dart';
import '../../features/activity_event/activity_events_list_view.dart';
import 'app_routes.dart';
import '../../features/leaders/my_leaders_view.dart';

class AppPages {
  static final pages = [
    GetPage(name: Routes.boot, page: () => const BootView()),
    GetPage(name: Routes.mobile, page: () => const MobileView()),
    GetPage(name: Routes.otp, page: () => const OtpView()),
    GetPage(name: Routes.profileBasics, page: () => const ProfileBasicsView()),
    GetPage(name: Routes.personal, page: () => const PersonalView()),
    GetPage(name: Routes.boothSelect, page: () => const BoothSelectView()),
    GetPage(name: Routes.consent, page: () => const ConsentView()),
    GetPage(name: Routes.shell, page: () => const ShellView()),
    GetPage(name: Routes.card, page: () => const MembershipCardView()),
    GetPage(name: Routes.profile, page: () => const ProfileOverviewView()),
    GetPage(name: Routes.profileEdit, page: () => const ProfileView()),
    GetPage(name: Routes.activityHub, page: () => const ActivityHubView()),
    GetPage(name: Routes.activityDetails, page: () => const ActivityDetailsView()),
    GetPage(name: Routes.activityConfirm, page: () => const ActivityConfirmView()),
    GetPage(name: Routes.activitySaved, page: () => const ActivitySavedView()),
    GetPage(name: Routes.activityRejected, page: () => const ActivityRejectedView()),
    GetPage(name: Routes.members, page: () => const MembersView()),
    GetPage(name: Routes.addMember, page: () => const AddMemberView()),
    GetPage(name: Routes.recruitConsent, page: () => const RecruitConsentView()),
    GetPage(name: Routes.districtHealth, page: () => const DistrictHealthView()),
    GetPage(name: Routes.meeting, page: () => const MeetingDetailView()),
    GetPage(name: Routes.checkIn, page: () => const CheckInView()),
    GetPage(name: Routes.tasks, page: () => const TasksView()),
    GetPage(name: Routes.createTask, page: () => const CreateTaskView()),
    GetPage(name: Routes.sync, page: () => const SyncView()),
    GetPage(name: Routes.notifications, page: () => const NotificationsView()),
    GetPage(name: Routes.verification, page: () => const VerificationInboxView()),
    GetPage(name: Routes.memberStatus, page: () => const MemberStatusView()),
    GetPage(name: Routes.apiSettings, page: () => const ApiSettingsView()),
    GetPage(name: Routes.errorLog, page: () => const ErrorLogView()),
    GetPage(name: Routes.youtubePlayer, page: () => const YoutubePlayerView()),
    GetPage(
      name: Routes.recentVideos,
      page: () {
        final home = Get.find<SessionController>().home.value;
        return HomeFeedListView(
          title: 'recent_videos'.tr,
          items: feedItemsFrom(home?['recentVideos'] as List?, fallback: recentVideos),
        );
      },
    ),
    GetPage(
      name: Routes.recentBlogs,
      page: () {
        final home = Get.find<SessionController>().home.value;
        return HomeFeedListView(
          title: 'recent_blogs'.tr,
          items: feedItemsFrom(home?['recentBlogs'] as List?, fallback: recentBlogs),
        );
      },
    ),
    GetPage(
      name: Routes.nearbyActivity,
      page: () {
        final home = Get.find<SessionController>().home.value;
        return HomeFeedListView(
          title: 'recent_activity_near'.tr,
          items: nearbyActivitiesFrom(home?['nearbyActivities'] as List?),
        );
      },
    ),
    GetPage(name: Routes.upcomingEvents, page: () => const UpcomingEventsView()),
    GetPage(name: Routes.createEvent, page: () => const CreateEventView()),
    GetPage(name: Routes.eventDetail, page: () => const EventDetailView()),
    GetPage(name: Routes.engagementPlay, page: () => const EngagementPlayView()),
    GetPage(name: Routes.activityEvents, page: () => const ActivityEventsListView()),
    GetPage(name: Routes.activityEventPlay, page: () => const ActivityEventPlayView()),
    GetPage(name: Routes.posts, page: () => const PostsListView()),
    GetPage(name: Routes.createPost, page: () => const CreatePostView()),
    GetPage(name: Routes.postVideo, page: () => const PostVideoPlayerView()),
    GetPage(name: Routes.postDetail, page: () => const PostDetailView()),
    GetPage(name: Routes.grievance, page: () => const GrievanceView()),
    GetPage(name: Routes.myLeaders, page: () => const MyLeadersView()),
  ];
}
