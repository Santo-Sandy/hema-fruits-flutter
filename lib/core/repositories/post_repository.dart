import 'package:cashew_marketplace/shared/local_storage/hive_service.dart';
import 'package:hive/hive.dart';

class PostRepository {
  PostRepository._();

  static final PostRepository instance = PostRepository._();

  final HiveService _hive = HiveService.instance;

  static const String boxName = HiveBoxes.posts;

  static const String myPostsKey = 'my_posts';
  static const String newPostsKey = 'new_posts';

  static const String favoritePostsKey = 'favorite_posts';

  static const String recentPostsKey = 'recent_posts';
  static const String recentKernelPostsKey = 'recent_Kernel_posts';

  static const String viewedPostsKey = 'viewed_posts';

  static const String biddingPostsKey = 'bidding_posts';
  static const String userPostsKey = 'user_posts';

  // ==================================================
  // POSTS
  // ==================================================

  Future<void> savePost(Map<String, dynamic> post) async {
    await _hive.put(boxName: boxName, key: post['_id'], value: post);
  }

  Future<void> savePosts(List<Map<String, dynamic>> posts) async {
    final Map<String, dynamic> data = {};

    for (final post in posts) {
      data[post['_id']] = post;
    }

    await _hive.putAll(boxName: boxName, values: data);
  }

  Map<String, dynamic>? getPost(String postId) {
    final data = _hive.get<Map>(boxName: boxName, key: postId);

    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> getAllPosts() {
    final box = Hive.box(boxName);

    return box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e.containsKey('_id'))
        .toList();
  }

  Future<void> deletePost(String postId) async {
    await _hive.delete(boxName: boxName, key: postId);
  }

  // ==================================================
  // UPDATE POST
  // ==================================================

  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    final post = getPost(postId);

    if (post == null) return;

    post.addAll(updates);

    await savePost(post);
  }

  // ==================================================
  // MY POSTS
  // ==================================================

  Future<void> saveMyPosts(List<Map<String, dynamic>> posts) async {
    // Save actual posts
    await savePosts(posts);

    // Save only ids for my posts
    final ids = posts.map<String>((e) => e['_id'].toString()).toList();

    await _hive.put(boxName: boxName, key: myPostsKey, value: ids);
  }

  Future<void> addMyPost(Map<String, dynamic> post) async {
    await savePost(post);
    final ids = getMyPostsIds();
    if (!ids.contains(post['_id'])) {
      ids.insert(0, post['_id'].toString());
      await _hive.put(boxName: boxName, key: myPostsKey, value: ids);
    }
  }

  List<String> getMyPostsIds() {
    return List<String>.from(
      _hive.get<List>(boxName: boxName, key: myPostsKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getMyPosts() {
    return getMyPostsIds()
        .map(getPost)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> clearMyPosts() async {
    await _hive.put(boxName: boxName, key: myPostsKey, value: []);
  }

  // ==================================================
  // Recent
  // ==================================================
  Future<void> saveRecentPosts(List<Map<String, dynamic>> posts) async {
    await savePosts(posts);

    final ids = posts.map<String>((e) => e['_id'].toString()).toList();

    await _hive.put(boxName: boxName, key: recentPostsKey, value: ids);
  }

  List<String> getRecentIds() {
    return List<String>.from(
      _hive.get<List>(boxName: boxName, key: recentPostsKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getRecentPosts() {
    return getRecentIds()
        .map(getPost)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> clearRecentPosts() async {
    await _hive.put(boxName: boxName, key: recentPostsKey, value: []);
  }

  Future<void> saveRecentKernelPosts(List<Map<String, dynamic>> posts) async {
    await savePosts(posts);

    final ids = posts.map<String>((e) => e['_id'].toString()).toList();

    await _hive.put(boxName: boxName, key: recentKernelPostsKey, value: ids);
  }

  List<String> getRecentKernelIds() {
    return List<String>.from(
      _hive.get<List>(boxName: boxName, key: recentKernelPostsKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getRecentKernelPosts() {
    return getRecentKernelIds()
        .map(getPost)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> clearRecentKernelPosts() async {
    await _hive.put(boxName: boxName, key: recentKernelPostsKey, value: []);
  }

  // ==================================================
  // New
  // ==================================================
  Future<void> saveNewPosts(List<Map<String, dynamic>> posts) async {
    await savePosts(posts);

    final ids = posts.map<String>((e) => e['_id'].toString()).toList();

    await _hive.put(boxName: boxName, key: newPostsKey, value: ids);
  }

  Future<void> addNew(String postId) async {
    final ids = getNewIds();

    if (!ids.contains(postId)) {
      ids.add(postId);

      await _hive.put(boxName: boxName, key: newPostsKey, value: ids);
    }
  }

  Future<void> removeNew(String postId) async {
    final ids = getNewIds();

    ids.remove(postId);

    await _hive.put(boxName: boxName, key: newPostsKey, value: ids);
  }

  List<String> getNewIds() {
    return List<String>.from(
      _hive.get<List>(boxName: boxName, key: newPostsKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getNewPosts() {
    return getNewIds().map(getPost).whereType<Map<String, dynamic>>().toList();
  }

  Future<void> clearNewPosts() async {
    await _hive.put(boxName: boxName, key: newPostsKey, value: []);
  }

  // ==================================================
  // FAVORITES
  // ==================================================
  Future<void> saveFavoritePosts(List<Map<String, dynamic>> posts) async {
    final existingPosts = getFavoritePosts();

    final Map<String, Map<String, dynamic>> postMap = {
      for (final post in existingPosts)
        post['_id'].toString(): Map<String, dynamic>.from(post),
    };

    for (final post in posts) {
      final id = post['_id'].toString();
      postMap[id] = Map<String, dynamic>.from(post);
    }

    final updatedPosts = postMap.values.toList();

    await savePosts(updatedPosts);

    final ids = updatedPosts
        .map<String>((post) => post['_id'].toString())
        .toList();

    await _hive.put(boxName: boxName, key: favoritePostsKey, value: ids);
  }

  Future<void> addFavoritePost(Map<String, dynamic> post) async {
    await savePosts([post]);

    final ids = getFavoriteIds().toList();

    final id = post['_id'].toString();

    if (!ids.contains(id)) {
      ids.add(id);

      await _hive.put(boxName: boxName, key: favoritePostsKey, value: ids);
    }
  }

  Future<void> addFavorite(String postId) async {
    final ids = getFavoriteIds();

    if (!ids.contains(postId)) {
      ids.add(postId);

      await _hive.put(boxName: boxName, key: favoritePostsKey, value: ids);
    }
  }

  Future<void> removeFavorite(String postId) async {
    final ids = getFavoriteIds();

    ids.remove(postId);

    await _hive.put(boxName: boxName, key: favoritePostsKey, value: ids);
  }

  List<String> getFavoriteIds() {
    return List<String>.from(
      _hive.get<List>(boxName: boxName, key: favoritePostsKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getFavoritePosts() {
    return getFavoriteIds()
        .map(getPost)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> clearFavoritePosts() async {
    await _hive.put(boxName: boxName, key: favoritePostsKey, value: []);
  }

  // ==================================================
  // VIEWED POSTS
  // ==================================================
  Future<void> saveViewedPosts(List<Map<String, dynamic>> posts) async {
    await savePosts(posts);

    final ids = posts.map<String>((e) => e['_id'].toString()).toSet().toList();

    await _hive.put(boxName: boxName, key: viewedPostsKey, value: ids);
  }

  Future<void> addViewedPost(String postId) async {
    final ids = getViewedPostIds();

    if (!ids.contains(postId)) {
      ids.insert(0, postId);

      await _hive.put(boxName: boxName, key: viewedPostsKey, value: ids);
    }
  }

  List<String> getViewedPostIds() {
    return List<String>.from(
      _hive.get<List>(boxName: boxName, key: viewedPostsKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getViewedPosts() {
    return getViewedPostIds()
        .map(getPost)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> clearViewedPosts() async {
    await _hive.put(boxName: boxName, key: viewedPostsKey, value: []);
  }

  // ==================================================
  // BIDDING POSTS
  // ==================================================
  Future<void> saveBiddingPosts(List<Map<String, dynamic>> posts) async {
    await savePosts(posts);

    final ids = posts.map<String>((e) => e['_id'].toString()).toList();

    await _hive.put(boxName: boxName, key: biddingPostsKey, value: ids);
  }

  Future<void> addBiddingPost(String postId) async {
    final ids = getBiddingPostIds();

    if (!ids.contains(postId)) {
      ids.add(postId);

      await _hive.put(boxName: boxName, key: biddingPostsKey, value: ids);
    }
  }

  List<String> getBiddingPostIds() {
    return List<String>.from(
      _hive.get<List>(boxName: boxName, key: biddingPostsKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getBiddingPosts() {
    return getBiddingPostIds()
        .map(getPost)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> clearBiddingPosts() async {
    await _hive.put(boxName: boxName, key: biddingPostsKey, value: []);
  }
  // ==================================================
  // USER POSTS
  // ==================================================

  Future<void> saveUserPosts(
    List<Map<String, dynamic>> posts,
    String userId,
  ) async {
    await savePosts(posts);

    final userPosts = _hive.get(boxName: boxName, key: userPostsKey) ?? {};

    userPosts[userId] = posts.map((e) => e['_id'].toString()).toList();
    await _hive.put(boxName: boxName, key: userPostsKey, value: userPosts);
  }

  // Future<void> addUserPost(String userId, String postId) async {
  //   final userPosts = getUserPostsMap();
  //   final ids = List<String>.from(userPosts[userId] ?? []);
  //   if (!ids.contains(postId)) {
  //     ids.add(postId);
  //     userPosts[userId] = ids;
  //     await _hive.put(boxName: boxName, key: userPostsKey, value: userPosts);
  //   }
  // }

  Map<String, dynamic> getUserPostsMap() {
    return Map<String, dynamic>.from(
      _hive.get(boxName: boxName, key: userPostsKey) ?? {},
    );
  }

  List<Map<String, dynamic>> getUserPosts(String userId) {
    final userPosts = getUserPostsMap();

    final ids = List<String>.from(userPosts[userId] ?? []);

    return ids.map(getPost).whereType<Map<String, dynamic>>().toList();
  }

  Future<void> clearUserPosts(String userId) async {
    final userPosts = Map<String, dynamic>.from(
      _hive.get(boxName: boxName, key: userPostsKey) ?? {},
    );

    userPosts.remove(userId);

    await _hive.put(boxName: boxName, key: userPostsKey, value: userPosts);
  }
  // ==================================================
  // CLEAR
  // ==================================================

  Future<void> clearPosts() async {
    await _hive.clearBox(boxName: boxName);
  }
}
