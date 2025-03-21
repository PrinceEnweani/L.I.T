const String fb_app_id = "367344998058010";
const String fb_redirect_url =
    "https://litt-a9ee1.firebaseapp.com/__/auth/handler";
//const String fcm_server_key="AAAAIIcvVLc:APA91bHhCJf1jm0bk5HBo_fW3vjCcz-gIJEOkLVkBzaKUsdL8NMOhIrjIrmrrCzn5gREy36FWX-cDXORqxBNNClBXTekOU0QtI5_P6Oac7vjKw1QM52KWEeRfppyBs19dwhx_tsOMViw";
const String fcm_server_key =
    "AAAAbbILvUc:APA91bGH-NSgvJOkABjv0LaSaDp0cxnLxPk84oGGoLypO7kGqDrJc05HwOB2ugfBvZHHOLR_96XKeaXR73sS05vhfnpKTd_hwb7_oh4BmjEUDmprC4INLolLXrLaZHzIg5JoWNg6ok-S";
const int birthday_page_idx = 0;
const int category_preference_page_idx = 1;
const int gender_page_idx = 2;
const int preference_page_idx = 3;
const int location_page_idx = 4;
const String stripe_public_key =
    "pk_test_51JAYx1DQIZSnlOxktXaMmcre94MbqgmK0o8dkITRPLFmlWRZ6r8321OCUYEpbpeywnKTlI4KzO7zQVQC3aJyoC2l00Lf8BFAlm";
const String stripe_secrete_key =
    "sk_test_51JAYx1DQIZSnlOxkK0WzXs83DQPNJzLMfysYNJzIjSYRdmzTp0KtK7WD2WPCvYxmJdtfjDSXb2EZQOcPlTmYOnzK00vK8fdIXB";
const String emailServiceUrl =
    "https://us-central1-litt-a9ee1.cloudfunctions.net/sendMail";
const String ticketImageUrl =
    "https://us-central1-litt-a9ee1.cloudfunctions.net/viewTicket";
const String litPlaceHolder =
    "https://images.unsplash.com/photo-1607827448387-a67db1383b59?ixid=MnwxMjA3fDB8MHxzZWFyY2h8N3x8cGxhY2Vob2xkZXJ8ZW58MHx8MHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60";
//Auth error codes
const String auth_invalid_email_error_code =
    "ERROR : Your email is invalid, check and try again.";
const String auth_wrong_password_error_code =
    "ERROR : Your email or password is incorrect.";
const String auth_no_user_error_code =
    "ERROR : No account exists with this email.";
const String auth_user_diabled_error_code =
    "ERROR : Your account is disabled. Contact support or try again.";
const String auth_too_many_request_error_code =
    "ERROR : too many attempts... try again later...";
const String auth_operation_not_allowed_error_code =
    "ERROR : Nice try, but that's not allowed :/";
const String auth_email_exists_error_code =
    "ERROR : An account with this email already exists.\nLogin or use a different email.";
const String MAPS_KEY = 'AIzaSyCjYd92XrLthFK7mvaJ_LPV1iNeurnx9MQ';
//TAGS FOR EVENTS AND NAV ARGS
const String CREATE_LITUATION_TAG = 'create';
//DB Constants
const String db_users_collection = 'users';
const String db_lituations_categories_collection = 'users_lituations';
const String db_user_lituations_collection = 'users_lituations';
const String db_lituations_collection = 'lituations';
const String db_vibed_collection = 'vibed';
const String db_vibing_collection = 'vibing';
const String db_user_vibe_collection = 'userVibe';
const String db_user_status_collection = 'status';
const String db_user_settings_collection = 'users_settings';
const String db_user_activity_collection = 'users_activity';
const String db_user_setting_vibe = 'vibe_visibility';
const String db_user_setting_lituation = 'lituation_visibility';
const String db_user_setting_activity = 'activity_visibility';
const String db_user_setting_location = 'location_visibility';
const String db_user_setting_invitation_notifications =
    'invitation_notifications';
const String db_user_setting_lituation_notifications =
    'lituation_notifications';
const String db_user_setting_general_notifications = 'general_notifications';
const String db_user_setting_chat_notifications = 'chat_notifications';
const String db_user_setting_vibe_notifications = 'vibe_notifications';
const String db_user_setting_adult_lituations = 'adult_lituations';
const String db_user_setting_theme = 'theme';
String logo = 'assets/images/litlogo.png';
// QR BEGIN
const String QR_ID = "LITUATION";
const String LIT_PENDING = "pending";
const String LIT_ONGOING = "ongoing";
const String LIT_ALMOSTOVER = "almost_over";
const String LIT_OVER = "over";
