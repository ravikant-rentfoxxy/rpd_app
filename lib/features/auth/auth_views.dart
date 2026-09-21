import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../session/session_controller.dart';
import '../../core/widgets/flash.dart';

class MobileView extends StatefulWidget {
  const MobileView({super.key});

  @override
  State<MobileView> createState() => _MobileViewState();
}

class _MobileViewState extends State<MobileView> {
  final mobile = TextEditingController();
  final loading = false.obs;
  final locked = false.obs;

  @override
  void dispose() {
    mobile.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final number = mobile.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(number)) {
      flash('Error', 'Enter a 10-digit Indian mobile number');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    locked.value = true;
    loading.value = true;
    try {
      await Get.find<SessionController>().requestOtp(number);
      // Drop the overlay before pushing, so it is gone when this screen is shown again.
      loading.value = false;
      await Get.toNamed(Routes.otp, arguments: number);
      if (mounted) locked.value = false;
    } catch (e, stack) {
      AppLog.error('OTP request failed', error: e, stack: stack, tag: 'AUTH');
      flash('Error', apiErrorMessage(e));
      locked.value = false;
    } finally {
      loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.loginNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      LanguageDropdown(onDark: true),
                      Spacer(),
                      _LoginLogo(),
                    ],
                  ),
                  const Spacer(),
                  DisplayText('your_mobile'.tr, color: Colors.white, size: 26),
                  const SizedBox(height: 6),
                  Text('mobile_help'.tr, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13)),
                  const SizedBox(height: 16),
                  Text(
                    'mobile_number'.tr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => LoginMobileField(
                      controller: mobile,
                      readOnly: locked.value,
                    ),
                  ),
                  Obx(
                    () => PrimaryButton(
                      'send_code'.tr,
                      enabled: !loading.value,
                      onTap: _sendOtp,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'terms_line'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          Obx(() => ScreenLoader(visible: loading.value, message: 'sending_code'.tr)),
        ],
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/login_bg.jpg',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/login_logo.jpg',
        width: 72,
        height: 72,
        fit: BoxFit.cover,
      ),
    );
  }
}

class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final code = TextEditingController();
  final loading = false.obs;
  final otpTick = 0.obs;
  late final String mobile;

  @override
  void initState() {
    super.initState();
    mobile = (Get.arguments as String?) ?? Get.find<HiveService>().draft.get('mobile') as String? ?? '';
    code.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    code.removeListener(_onCodeChanged);
    code.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    otpTick.value++;
    final otp = code.text.replaceAll(RegExp(r'\D'), '');
    if (otp.length == 6 && !loading.value) {
      _verify(otp);
    }
  }

  Future<void> _verify(String otp) async {
    if (loading.value || !RegExp(r'^\d{6}$').hasMatch(otp)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    loading.value = true;
    try {
      await Get.find<SessionController>().verifyOtp(mobile, otp);
    } catch (e, stack) {
      AppLog.error('OTP verify failed', error: e, stack: stack, tag: 'AUTH');
      flash('Error', apiErrorMessage(e));
    } finally {
      loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.loginNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.screen),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpace.screen * 2),
                  // No IntrinsicHeight here: OtpBoxes uses a LayoutBuilder, which can't report intrinsic sizes.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: Get.back,
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.25),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                              shape: const CircleBorder(),
                              fixedSize: const Size(40, 40),
                            ),
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                          ),
                          const Spacer(),
                          const _LoginLogo(),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DisplayText('enter_code'.tr, color: Colors.white, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            'code_sent'.tr,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '+91 $mobile · ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: Get.back,
                                child: Text(
                                  'change'.tr,
                                  style: const TextStyle(
                                    color: Color(0xFFEF8120),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFFEF8120),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OtpBoxes(controller: code, onChanged: (_) => otpTick.value++),
                          const SizedBox(height: 16),
                          Obx(() {
                            otpTick.value;
                            return PrimaryButton(
                              'continue'.tr,
                              enabled: !loading.value && code.text.replaceAll(RegExp(r'\D'), '').length == 6,
                              onTap: () => _verify(code.text.replaceAll(RegExp(r'\D'), '')),
                            );
                          }),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              '${'resend'.tr} · ${'sms_instead'.tr}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Obx(() => ScreenLoader(visible: loading.value, message: 'verifying_code'.tr)),
        ],
      ),
    );
  }
}
