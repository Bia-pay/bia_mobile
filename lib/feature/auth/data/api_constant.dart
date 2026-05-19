class ApiConstant {
  // ------------- BASE URL LINK -------------------
  static const BASE_URL = 'https://api.bia.com.ng';
  // ------------ USER SIGN
  static const LOGIN = '/api/v1/auth/login';
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
  static const FAVOURITE_TRANSFER = "/api/v1/wallet/beneficiaries?page=1&limit=10";
  static const WALLET_BALANCE = '/api/v1/wallet/balance';
  static const VERIFY_ACCOUNT = '/api/v1/wallet/transfer/verify';
  static const GENERATE_QR_CODE = '/api/v1/user/qr-code';
  static const RECENT_TRANSFER = '/api/v1/wallet/recent-transfers';
  static const PROFILE_UPDATE = '/api/v1/user/profile';
  static const REFRESH_TOKEN = '/api/v1/auth/refresh/token';
  static const DEPOSIT = '/api/v1/payment/deposit';
  static const VERIFY_PAYMENT = '/api/v1/payment/deposit/verify';
  static const UPDATE_AVATAR = '/api/v1/user/profile/image';
  static const LOGOUT = "/api/v1/auth/logout";
  static const BANK_TRANSFER = '/api/v1/payment/bank/transfer';
  static const GET_BANKS= '/api/v1/payment/banks';
  static const VERIFY_BANK_ACCOUNT= '/api/v1/payment/account/verify';
  static const VERIFY_BANK_TRANSFER = "/api/v1/payment/bank/transfer/verify";
  static const RECENT_BANK_TRANSFERS = "/api/v1/payment/recent-transfers";
  static const BENEFICIARIES = "/api/v1/payment/beneficiaries/";
  static const FORGOT_PIN = "/api/v1/user/forgot-pin";
  static const VERIFY_FORGOT_PIN = "/api/v1/user/verify-forgot-pin";
  static const RESTORE_FORGOT_PIN = "/api/v1/user/change-pin";
  static const VERIFY_PHONE = "/api/v1/billpayment/phone/verify";
  static const BUY_AIRTIME = "/api/v1/billpayment/airtime/purchase";
  static const String DATA_PURCHASE = '/api/v1/billpayment/data/purchase';
  static const String DATA_PLANS = '/api/v1/billpayment/data/plans';
  static const String GET_DATA_PLANS = '/api/v1/billpayment/data/plans?serviceID=mtn-data';
  static const GET_CABLE_PROVIDERS = "/api/v1/billpayment/cabletv/service-ids";
  static const GET_CABLE_VARIATION = "/api/v1/billpayment/cabletv/variation-codes?serviceID=";
  static const String VERIFY_SMART_CARD = '/api/v1/billpayment/cabletv/card/verify';
  static const String PURCHASE_CABLE = '/api/v1/billpayment/cabletv/purchase';
  static const String GET_ELECTRICITY_PROVIDERS = "/api/v1/billpayment/electricity/service-ids";
  static const String VERIFY_ELECTRICITY_METER = '/api/v1/billpayment/electricity/meter/verify';
  static const String PURCHASE_ELECTRICITY_UNIT = '/api/v1/billpayment/electricity/purchase';
  static const String GET_CHARGES = "/api/v1/payment/charges";
  static const String UPDATE_TAG = '/api/v1/user/tag';

  // ------------ NOTIFICATIONS
  static const String GET_NOTIFICATIONS = '/api/v1/notification';
  static const String UNREAD_NOTIFICATION_COUNT = '/api/v1/notification/unread-count';
  static const String MARK_ALL_NOTIFICATIONS_READ = '/api/v1/notification/read-all';
  static String MARK_NOTIFICATION_READ(String id) => '/api/v1/notification/$id/read';
}
