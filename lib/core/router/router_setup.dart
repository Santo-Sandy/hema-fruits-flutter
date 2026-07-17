class RouteName {
  RouteName._();
  // auth login page
  static const ssoLogin = 'login';
  static const profileSetup = 'profileSetup';
  static const companySetup = 'companySetup';

  // Main shell (footer tabs)
  static const home = 'home';
  static const homeView = 'home-view';
  static const homeNew = 'home-new';
  static const homeFav = 'home-fav';
  static const userProfile = 'user-profile';
  static const dashboard = 'dashboard';
  static const myActivity = 'my-activity';
  static const myActivityPost = 'my-activity-post';
  static const myActivityResponses = 'my-activity-responses';
  static const myEnquiry = 'my-enquiry';
  static const myEnquiryView = 'my-enquiry-view';
  static const salesBuyBidding = 'sales-buy-bidding';
  // Profile area
  static const profile = 'profile';
  static const settings = 'settings';
  static const menu = 'menu';
  static const blocked = 'blocked';
  static const personalInfo = 'personal-info';
  static const businessInfo = 'business-info';
  static const creditpoint = 'creditpoint';
  static const creditPayment = 'creditPayment';
  static const notificationsHistory = 'notifications-history';
  static const offlineQueue = 'offline-queue';

  // Post
  static const postList = 'post';
  static const postBuyer = 'post-view';
  static const postSeller = 'seller-post';
  static const postofflineBuyer = 'postsoff';
  static const postofflineSeller = 'sellerpostsoff';
  static const newPost = 'new-posts';

  // ignore: constant_identifier_names
  static const ResponseBuyerpost = 'buyer-post-view';
  // ignore: constant_identifier_names
  static const ResponseSellerpost = 'seller-post-view';

  static const myResponseBuyerpost = 'my-buyer-post-view';
  static const myResponseSellerpost = 'my-seller-post-view';

  static const viewScreen = 'view-screen';
  static const sellerViewScreen = 'seller-view-screen';

  static const buyerResponseviewScreen = 'buyer-response-view-screen';
  static const sellerResponseviewScreen = 'seller-response-view-screen';
}

class RoutePath {
  RoutePath._();

  static const home = '/home';
  static const homeview = 'homeview';
  static const homenew = 'homenew';
  static const homefav = 'homefav';
  static const userProfile = '/userprofile';
  static const dashboard = '/dashboard';
  static const myActivity = '/activity';
  static const myEnquiry = '/enquiry';
  static const myEnquiryView = '/enquiry/view';
  static const myActivityPost = '/activity/post';
  static const myActivityResponses = '/activity/responses';
  static const salesBuyBidding = '/salesbuybidding';

  static const profile = '/profile';
  static const settings = '/settings';
  static const menu = '/menu';
  static const blocked = '/blocked';
  static const personalInfo = '/personal-info';
  static const businessInfo = '/business-info';
  static const creditpoint = '/creditpoint';
  static const creditpayment = '/creditpayment';
  static const notificationshistory = '/notifications_history';
  static const offlineQueue = '/offline-queue';

  static const posts = '/posts';
  static const postBuyer = '/posts/:id';
  static const postSeller = '/sellerposts/:id';
  static const postofflineBuyer = '/postsoff/:id';
  static const postofflineSeller = '/sellerpostsoff/:id';
  static const newPost = '/newposts';

  // static const ResponseBuyerpost = '/buyerpostview/:id';
  // static const ResponseSellerpost = '/sellerpostview/:id';

  static const myResponseSellerpost = '/mysellerpostview/:id';
  static const myResponseBuyerpost = '/mybuyerpostview/:id';

  static const viewscreen = '/viewscreen/:id';
  static const sellerviewscreen = '/sellerviewscreen/:id';

  static const buyerResponseviewscreen = '/buyerresponseviewscreen/:id';
  static const sellerResponseviewscreen = '/sellerresponseviewscreen/:id';
}
