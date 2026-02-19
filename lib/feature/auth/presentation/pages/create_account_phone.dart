import 'package:bia/core/__core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/widgets/phone_input_widget.dart';
import '../../authcontroller/authcontroller.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';

class PhoneRegScreen extends ConsumerStatefulWidget {
  const PhoneRegScreen({super.key});

  @override
  ConsumerState<PhoneRegScreen> createState() => _PhoneRegScreenState();
}

class _PhoneRegScreenState extends ConsumerState<PhoneRegScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _agreed = false;
  final bool _isLoading = false;
  String _countryDialCode = '234';
  final FocusNode phoneFocusNode = FocusNode();

  bool get _canProceed =>
      phoneController.text.trim().isNotEmpty && _agreed;


  @override
  void initState() {
    super.initState();
    phoneController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          /// 🔥 Background Image
          Positioned.fill(
            child: Image.asset(
              login,
              fit: BoxFit.cover,
            ),
          ),

          /// 🔥 Light Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final screenWidth = constraints.maxWidth;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 500, // tablet support
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.06,
                        screenHeight * 0.08,
                        screenWidth * 0.06,
                        MediaQuery.of(context).viewInsets.bottom + 20.h,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          /// 🔹 Title
                          Text(
                            'Create Your Account',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 26.spMin,
                            ),
                          ),

                          SizedBox(height: 8.h),

                          Text(
                            'Enter your phone number',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontSize: 16.spMin),
                          ),

                          SizedBox(height: screenHeight * 0.05),

                          /// 🔹 Phone Input (UNCHANGED)
                          PhoneInputWidget(
                            controller: phoneController,
                            focusNode: phoneFocusNode,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) async {
                              if (!_canProceed) return;

                              FocusScope.of(context).unfocus();

                              if (!_agreed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'You must agree to the Terms & Conditions'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final rawPhone = phoneController.text.trim();
                              final normalizedPhone =
                              rawPhone.startsWith('0')
                                  ? rawPhone.substring(1)
                                  : rawPhone;

                              final fullPhoneNumber =
                                  '$_countryDialCode$normalizedPhone';

                              final authState =
                              ref.read(authControllerProvider.notifier);

                              final response =
                              await authState.registerStepOne(
                                context,
                                fullPhoneNumber,
                              );

                              if (response?.responseSuccessful == true) {
                                context.pushNamed(
                                  RouteList.createAccountVerifyOtpScreen,
                                  extra: fullPhoneNumber,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response?.responseMessage ??
                                          'Registration failed',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            label: 'Mobile Number',
                            hintText: '8012345678',
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Phone number is required';
                              }
                              if (value.length < 10) {
                                return 'Phone number too short';
                              }
                              return null;
                            },
                            onCountryChanged: (country) {
                              _countryDialCode =
                                  country.dialCode.replaceAll('+', '');
                            },
                          ),

                          SizedBox(height: 20.h),

                          /// 🔹 Checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agreed,
                                onChanged: (v) =>
                                    setState(() => _agreed = v ?? false),
                                activeColor: primaryColor,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 12.h),
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'I agree with ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                      children: [
                                        TextSpan(
                                          text: 'Terms & Conditions',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20.h),

                          /// 🔹 Button (UNCHANGED LOGIC)
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              buttonColor:
                              _canProceed ? primaryColor : inactiveColor,
                              buttonTextColor: Colors.white,
                              buttonName:
                              _isLoading ? 'Please wait...' : 'Next',
                              buttonBorderColor: Colors.transparent,
                              onPressed: (!_canProceed || _isLoading)
                                  ? null
                                  : () async {
                                FocusScope.of(context).unfocus();

                                if (!_agreed) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'You must agree to the Terms & Conditions'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final rawPhone =
                                phoneController.text.trim();
                                final normalizedPhone =
                                rawPhone.startsWith('0')
                                    ? rawPhone.substring(1)
                                    : rawPhone;

                                final fullPhoneNumber =
                                    '$_countryDialCode$normalizedPhone';

                                final authState = ref.read(
                                    authControllerProvider.notifier);

                                final response =
                                await authState.registerStepOne(
                                  context,
                                  fullPhoneNumber,
                                );

                                if (response?.responseSuccessful ==
                                    true) {
                                  context.pushNamed(
                                    RouteList
                                        .createAccountVerifyOtpScreen,
                                    extra: fullPhoneNumber,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response?.responseMessage ??
                                            'Registration failed',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),

                          SizedBox(height: 30.h),

                          /// 🔹 Sign In
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: "Already have an account?  ",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Sign In',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => context.pushNamed(
                                        RouteList.loginScreen),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}