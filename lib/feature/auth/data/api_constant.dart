class ApiConstant {

  // ------------- BASE URL LINK -------------------
  static const BASE_URL = 'https://api.bia.com.ng';


  // ------------ USER SIGN
  static const LOGIN = '/api/v1/auth/login';

  // ----------------- SIGN UP---------------
  static const REGISTER_STEP_ONE = '/api/v1/auth/register';
  static const REGISTER_STEP_TWO = '/api/v1/auth/verify/otp';
  static const RESEND_OTP = '/api/v1/auth/resend/otp';
  static const REGISTER_STEP_THREE = '/api/v1/auth/complete/registration';
  static const FORGET_PASSWORD = '/api/v1/auth/forgot/password';
  static const RESET_PASSWORD = '/api/v1/auth/reset/password';
  static const PROFILE = '/api/v1/user/profile';
  static const SET_PIN = '/api/v1/user/set-pin';
  static const UPDATE_PIN = '/api/v1/user/update-pin';
  static const WALLET = '/api/v1/wallet';
  static const TRANSER = '/api/v1/wallet/transfer';
  static const TRANSACTION = '/api/v1/wallet/transactions';
  static const WALLET_BALANCE = '/api/v1/wallet/balance';
  static const VERIFY_ACCOUNT = '/api/v1/wallet/transfer/verify';
  static const GENERATE_QR_CODE = '/api/v1/user/qr-code';
  static const RECENT_TRANSFER = '/api/v1/wallet/recent-transfers';
  static const PROFILE_UPDATE = '/api/v1/user/profile';
  static const REFRESH_TOKEN = '/api/v1/auth/refresh/token';
  // static const WALLET = '/api/v1/wallet';
  // static const TRANSER = '/api/v1/wallet/transfer';
  // static const TRANSACTION = '/api/v1/wallet/transactions?page=1&limit=10';

}
