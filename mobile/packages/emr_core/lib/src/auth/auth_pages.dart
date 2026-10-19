import 'package:get/get.dart';

import 'auth_controllers.dart';
import 'auth_flow.dart';
import 'auth_views.dart';

/// Routes for the shared auth screens. Each screen gets its controller through a binding.
List<GetPage<dynamic>> authPages() => [
      GetPage<void>(name: AuthRoutes.splash, page: () => const SplashView()),
      GetPage<void>(
        name: AuthRoutes.login,
        page: () => const LoginView(),
        binding: BindingsBuilder(
          () => Get.lazyPut(() => LoginController(repo: Get.find(), session: Get.find(), flow: Get.find())),
        ),
      ),
      GetPage<void>(
        name: AuthRoutes.smsCode,
        page: () => const SmsCodeView(),
        binding: BindingsBuilder(
          () => Get.lazyPut(
            () => SmsCodeController(repo: Get.find(), session: Get.find(), flow: Get.find(), args: Get.arguments as SmsArgs),
          ),
        ),
      ),
      GetPage<void>(
        name: AuthRoutes.changePassword,
        page: () => const ChangePasswordView(),
        binding: BindingsBuilder(
          () => Get.lazyPut(() => ChangePasswordController(repo: Get.find(), session: Get.find(), flow: Get.find())),
        ),
      ),
      GetPage<void>(
        name: AuthRoutes.forgotPassword,
        page: () => const ForgotPasswordView(),
        binding: BindingsBuilder(() => Get.lazyPut(() => ForgotPasswordController(repo: Get.find()))),
      ),
      GetPage<void>(name: AuthRoutes.forceUpdate, page: () => const ForceUpdateView()),
    ];
