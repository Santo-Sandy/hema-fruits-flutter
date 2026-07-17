import 'package:cashew_marketplace/core/repositories/post_repository.dart';
import 'package:cashew_marketplace/core/repositories/response_repository.dart';
import 'package:cashew_marketplace/core/repositories/settings_repository.dart';
import 'package:cashew_marketplace/core/repositories/stock_repository.dart';
import 'package:cashew_marketplace/core/repositories/user_repository.dart';
import 'package:cashew_marketplace/core/services/offline_queue_service.dart';
import 'package:flutter/material.dart';
import '../services/feature_services.dart';

// ── Base Provider
abstract class BaseProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  void setLoading(bool v) {
    _loading = v;
    // notifyListeners();
  }

  void setError(String? e) {
    _error = e;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class UserProfProvider extends BaseProvider {
  bool isLoading = true;
  List<dynamic> post = [];

  Future<void> fetch({
    required String endpoint,
    required Map<String, dynamic> filterPayload,
    required String userId,
  }) async {
    try {
      setLoading(true);
      isLoading = true;
      PostService postService = PostService();

      final response = await postService.getPosts(
        endpoint: endpoint,
        data: filterPayload,
      );

      if (response['status'] == 200) {
        // post = response;
        final List<dynamic> responseData = response['data'][0]['response'];
        post = List<Map<String, dynamic>>.from(responseData);
        await UserRepository.instance.saveUsers(
          post.cast<Map<String, dynamic>>(),
        );
        notifyListeners();
        // allPosts = post.cast<PostModel>();
      } else {
        setError(response.statusMessage);
      }
    } catch (e) {
      debugPrintStack();
    } finally {
      post = UserRepository.instance.getUser(userId) as List<dynamic>? ?? [];
      setLoading(false);
      isLoading = false;
    }
    notifyListeners();
  }
}

class UserAccountProvider extends BaseProvider {
  bool isLoading = true;
  List<Map<String, dynamic>> post = [];

  Future<void> fetch({
    required String endpoint,
    required Map<String, dynamic> filterPayload,
    required String userId,
  }) async {
    try {
      setLoading(true);
      isLoading = true;
      PostService postService = PostService();

      final response = await postService.getPosts(
        endpoint: endpoint,
        data: filterPayload,
      );

      if (response['status'] == 200) {
        // post = response;
        final List<dynamic> responseData = response['data'][0]['response'];
        post = List<Map<String, dynamic>>.from(responseData);
        // await PostRepository.instance.clearUserPosts(userId);
        await PostRepository.instance.saveUserPosts(post, userId);
        notifyListeners();
        // allPosts = post.cast<PostModel>();
      } else {
        setError(response.statusMessage);
      }
    } catch (e) {
      debugPrintStack();
    } finally {
      try {
        post = PostRepository.instance.getUserPosts(userId);
      } catch (e) {
        debugPrintStack();
      }
      setLoading(false);
      isLoading = false;
    }
    notifyListeners();
  }
}

class EditPostProvider extends BaseProvider {
  bool isLoading = false;
  List<dynamic> post = [];
  Future<void> fetch({
    required String endpoint,
    required Map<String, dynamic> filterPayload,
  }) async {
    try {
      setLoading(true);
      isLoading = true;
      final response = await PostService().getPosts(
        endpoint: endpoint,
        data: filterPayload,
      );

      if (response is Map && response['status'] == 200) {
        final responsePayload = response['data'];
        final responseData =
            (responsePayload is List && responsePayload.isNotEmpty)
            ? responsePayload[0]['response']
            : null;
        if (responseData is List) {
          await SettingsLocalRepository.instance.clearOriginSettings();
          await SettingsLocalRepository.instance.saveOriginSettings(
            responseData.cast<Map<String, dynamic>>(),
          );
          post = List<Map<String, dynamic>>.from(responseData);
        }
      }
    } catch (e) {
      debugPrintStack();
    } finally {
      try {
        post = SettingsLocalRepository.instance.getOriginSettings();
      } catch (e) {
        debugPrintStack();
      }
    }
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }
}

// ── Post Provider
class PostProvider extends BaseProvider {
  final PostRepository _postRepo = PostRepository.instance;
  bool isLoading = false;
  bool hasMore = true;
  bool hasMoreNew = true;
  bool hasMoreViewed = true;
  bool hasMoreFavorite = true;
  bool isFetchingMore = false;
  bool isFetchingMoreNew = false;
  bool isFetchingMoreViewed = false;
  bool isFetchingMoreFavorite = false;
  List<dynamic> post = [];
  List<dynamic> viewedpost = [];
  List<dynamic> favoritepost = [];
  List<dynamic> posts = [];
  List<dynamic> singlepost = [];

  List<String> get origins {
    return post
        .where((e) => e["origin"] != null)
        .map<String>((e) => e["origin"].toString())
        .toSet()
        .toList();
  }

  List<String> get homeorigins {
    final data = post
        .where((e) => e["origin"] != null)
        .map<String>((e) => e["origin"].toString())
        .toSet()
        .toList();
    data.addAll(
      viewedpost
          .where((e) => e["origin"] != null && data.contains(e) == false)
          .map<String>((e) => e["origin"].toString())
          .toSet()
          .toList(),
    );
    data.addAll(
      favoritepost
          .where((e) => e["origin"] != null && data.contains(e) == false)
          .map<String>((e) => e["origin"].toString())
          .toSet()
          .toList(),
    );
    notifyListeners();
    return data.toSet().toList();
  }

  List<String> get homeposttype {
    final data = post
        .where((e) => e["post_type"] != null)
        .map<String>(
          (e) => e["post_type"].toString() == "stocks" ? "Sale" : "Purchase",
        )
        .toSet()
        .toList();
    data.addAll(
      viewedpost
          .where((e) => e["post_type"] != null && data.contains(e) == false)
          .map<String>(
            (e) => e["post_type"].toString() == "stocks" ? "Sale" : "Purchase",
          )
          .toSet()
          .toList(),
    );
    data.addAll(
      favoritepost
          .where((e) => e["post_type"] != null && data.contains(e) == false)
          .map<String>(
            (e) => e["post_type"].toString() == "stocks" ? "Sale" : "Purchase",
          )
          .toSet()
          .toList(),
    );
    notifyListeners();
    return data.toSet().toList();
  }

  Map<String, dynamic> postList(String id) {
    final postlist = [...post, ...viewedpost, ...favoritepost];
    return postlist.cast<Map<String, dynamic>>().firstWhere(
      (e) => e['_id'] == id,
    );
  }

  List<String> get hometype {
    final data = post
        .where((e) => e["type"] != null)
        .map<String>((e) => e["type"].toString())
        .toSet()
        .toList();
    data.addAll(
      viewedpost
          .where((e) => e["type"] != null && data.contains(e) == false)
          .map<String>((e) => e["type"].toString())
          .toSet()
          .toList(),
    );
    data.addAll(
      favoritepost
          .where((e) => e["type"] != null && data.contains(e) == false)
          .map<String>((e) => e["type"].toString())
          .toSet()
          .toList(),
    );
    notifyListeners();
    return data.toSet().toList();
  }

  List<String> get type {
    final data = post
        .where((e) => e["type"] != null)
        .map<String>((e) => e["type"].toString())
        .toSet()
        .toList();
    notifyListeners();
    return data.toSet().toList();
  }

  List<String> get posttype {
    final data = post
        .where((e) => e["post_type"] != null)
        .map<String>(
          (e) => e["post_type"].toString() == "stocks" ? "Sale" : "Purchase",
        )
        .toSet()
        .toList();
    notifyListeners();
    return data.toSet().toList();
  }

  List<String> get grades {
    return post
        .where(
          (e) => e['grade'] != null && e["grade"] != "" && e["grade"] != "RCN",
        )
        .map<String>((e) => e["grade"])
        .toSet()
        .toList();
  }

  List<String> get status {
    return post
        .where((e) => e['status'] != null)
        .map<String>((e) => e['status'].toString())
        .toSet()
        .toList();
  }

  Future<void> updatefav(String userId, bool isfav) async {
    if (isfav) {}
  }

  int limit = 30;
  int start = 0;
  int startnew = 0;
  int startviewed = 0;
  int startfavorite = 0;

  List<dynamic> _extractResponseList(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) {
          final payload = first['response'];
          if (payload is List) {
            return payload;
          }
        }
      }
    }
    return const [];
  }

  Future<void> postFetch({
    required String endpoint,
    required String userId,
    required Map<String, dynamic> filterPayload,
    bool loadMore = false,
    bool suppressLoading = false,
  }) async {
    if (!suppressLoading) {
      setLoading(true);
    }
    if (isFetchingMoreNew) return;

    if (loadMore) {
      isFetchingMoreNew = true;
    } else {
      startnew = 0;
      hasMoreNew = true;
      if (!suppressLoading) {
        setLoading(true); // only for first load
      }
    }

    final payload = {
      ...filterPayload,
      "start": startnew,
      "end": startnew + limit,
    };

    try {
      final response = await PostService().getPosts(
        endpoint: endpoint,
        data: payload,
      );

      if (response['status'] == 200) {
        final List<dynamic> responseData = _extractResponseList(response);

        if (loadMore) {
          post.addAll(responseData);
          await PostRepository.instance.saveNewPosts(
            post.cast<Map<String, dynamic>>(),
          );
        } else {
          await PostRepository.instance.clearNewPosts();
          final merged = [...responseData.cast<Map<String, dynamic>>()];
          post = List<dynamic>.from(merged);
          await PostRepository.instance.saveNewPosts(
            post.cast<Map<String, dynamic>>(),
          );
        }

        hasMoreNew = responseData.length >= limit;
        if (responseData.isNotEmpty) {
          startnew += limit;
        }
      } else {
        setError(response.toString());
      }
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      post = PostRepository.instance.getNewPosts();
      isFetchingMoreNew = false;
      if (!suppressLoading) {
        setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  void updateFavUI(String id, bool isfav) {
    _updateFavInList(post, id, isfav);
    _updateFavInList(favoritepost, id, isfav);
    _updateFavInList(viewedpost, id, isfav);
    _postRepo.updatePost(id, {
      'favorite': _postRepo.getPost(id)?['favorite'] ?? [],
    });
    notifyListeners();
  }

  void _updateFavInList(List<dynamic> list, String id, bool isfav) {
    for (int i = 0; i < list.length; i++) {
      if (list[i]['_id'] == id) {
        final favList = List<dynamic>.from(list[i]['favorite'] ?? []);
        if (isfav && !favList.contains(id)) {
          favList.add(id);
        } else if (!isfav) {
          favList.remove(id);
        }
        list[i] = {...list[i], 'favorite': favList};
        break;
      }
    }
  }

  Future<void> viewedpostFetch({
    required String endpoint,
    required String userId,
    required Map<String, dynamic> filterPayload,
    bool loadMore = false,
    bool suppressLoading = false,
  }) async {
    if (!suppressLoading) {
      setLoading(true);
    }
    if (isFetchingMoreViewed) return;

    if (loadMore) {
      isFetchingMoreViewed = true;
    } else {
      startviewed = 0;
      hasMoreViewed = true;
      if (!suppressLoading) {
        setLoading(true); // only for first load
      }
    }

    final payload = {
      ...filterPayload,
      "start": startviewed,
      "end": startviewed + limit,
    };

    try {
      final response = await PostService().getPosts(
        endpoint: endpoint,
        data: payload,
      );

      if (response['status'] == 200) {
        final List<dynamic> responseData = _extractResponseList(response);
        hasMoreViewed = false;

        if (loadMore) {
          viewedpost.addAll(responseData);
          await PostRepository.instance.saveViewedPosts(
            viewedpost.cast<Map<String, dynamic>>(),
          );
        } else {
          await PostRepository.instance.clearViewedPosts();
          viewedpost = List<dynamic>.from(responseData);
          await PostRepository.instance.saveViewedPosts(
            viewedpost.cast<Map<String, dynamic>>(),
          );
        }
        hasMoreViewed = responseData.length >= limit;
        if (responseData.isNotEmpty) {
          startviewed += limit;
        }
      } else {
        setError(response.toString());
      }
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      viewedpost = PostRepository.instance.getViewedPosts();
      isFetchingMoreViewed = false;
      if (!suppressLoading) {
        setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> favoritepostFetch({
    required String endpoint,
    required String userId,
    required Map<String, dynamic> filterPayload,
    bool loadMore = false,
    bool suppressLoading = false,
  }) async {
    if (!suppressLoading) {
      setLoading(true);
    }
    if (isFetchingMoreFavorite) return;

    if (loadMore) {
      isFetchingMoreFavorite = true;
    } else {
      startfavorite = 0;
      hasMoreFavorite = true;
      if (!suppressLoading) {
        setLoading(true); // only for first load
      }
    }

    final payload = {
      ...filterPayload,
      "start": startfavorite,
      "end": startfavorite + limit,
    };

    try {
      final response = await PostService().getPosts(
        endpoint: endpoint,
        data: payload,
      );

      if (response['status'] == 200) {
        final List<dynamic> responseData = _extractResponseList(response);
        hasMoreFavorite = false;

        if (loadMore) {
          favoritepost.addAll(responseData);
          await PostRepository.instance.saveFavoritePosts(
            favoritepost.cast<Map<String, dynamic>>(),
          );
        } else {
          favoritepost = List<dynamic>.from(responseData);
          await PostRepository.instance.clearFavoritePosts();
          await PostRepository.instance.saveFavoritePosts(
            favoritepost.cast<Map<String, dynamic>>(),
          );
        }

        hasMoreFavorite = responseData.length >= limit;
        if (responseData.isNotEmpty) {
          startfavorite += limit;
        }
      } else {
        setError(response.toString());
      }
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      favoritepost = PostRepository.instance.getFavoritePosts();
      isFetchingMoreFavorite = false;
      if (!suppressLoading) {
        setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> fetch({
    String? type,
    required String endpoint,
    required String userId,
    String? search,
    String? origin,
    required Map<String, dynamic> filterPayload,
    String? user,
    bool loadMore = false,
  }) async {
    setLoading(true);
    isLoading = true;
    if (isFetchingMore) return;

    if (loadMore) {
      isFetchingMore = true;
    } else {
      start = 0;
      hasMore = true;
      setLoading(true);
    }

    final payload = {...filterPayload, "start": start, "end": start + limit};

    final response = await PostService().getPosts(
      endpoint: endpoint,
      data: payload,
    );

    if (response['status'] == 200) {
      final List<dynamic> responseData = response['data'][0]['response'];

      if (responseData.isEmpty) {
        hasMore = false;
      } else {
        if (loadMore) {
          post.addAll(List<Map<String, dynamic>>.from(responseData));
        } else {
          post = List<Map<String, dynamic>>.from(responseData);
        }

        start += limit;
      }
    }
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }

  Future<void> action(
    String endpoint,
    bool? status,
    String id,
    String action,
    String userId,
  ) async {
    try {
      await UIUpdate(id, action, userId, status);
      ApiDioPostService postService = ApiDioPostService();
      final response = await postService.view(
        endpoint: endpoint,
        data: status == null ? null : {"status": status},
      );
      if (response['status'] == 200) {
        // UIUpdate(id, action, userId);
      } else {
        setError(response.toString());
      }
    } catch (e) {
      debugPrintStack();
    } finally {
      notifyListeners();
    }
  }

  Future<void> viewedupdate(String userId, String id) async {
    try {
      final index = post.indexWhere((e) => e["_id"] == id);
      final indexview = viewedpost.indexWhere((e) => e["_id"] == id);
      final indexfav = favoritepost.indexWhere((e) => e["_id"] == id);

      if (index != -1) {
        if (post[index]['viewed'] == null) {
          post[index]['viewed'] = <String>{};
        }
        final viewed = Set<String>.from(post[index]["viewed"] ?? []);
        viewed.add(userId);
        post[index]["viewed"] = viewed;
        viewedpost.add(post[index]);
        await PostRepository.instance.removeNew(post[index]['_id']);
        post.removeAt(index);
      }
      if (indexview != -1) {
        final viewed = Set<String>.from(viewedpost[indexview]["viewed"] ?? []);
        viewed.add(userId);
        viewedpost[indexview]["viewed"] = viewed;
        // (viewedpost[indexview]["viewed"] as Set).add(userId);
      }
      if (indexfav != -1) {
        final viewed = Set<String>.from(favoritepost[indexfav]["viewed"] ?? []);
        viewed.add(userId);
        favoritepost[indexfav]["viewed"] = viewed;
        // (favoritepost[indexfav]["viewed"] as Set).add(userId);
      }
      await PostRepository.instance.saveViewedPosts(
        viewedpost.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      debugPrintStack();
    }
    notifyListeners();
  }

  Future<void> UIUpdate(
    String id,
    String action,
    String userId,
    bool? status,
  ) async {
    try {
      if (action == 'viewed') {
        await viewedupdate(userId, id);
      }
      if (action == 'favorite') {
        final index = post.indexWhere((e) => e["_id"] == id);
        final indexview = viewedpost.indexWhere((e) => e["_id"] == id);
        final indexfav = favoritepost.indexWhere((e) => e["_id"] == id);

        if (index != -1) {
          final List poster = post[index]['favorite'] ?? [];
          if (status != true && poster.contains(userId)) {
            final favorites = List.from(post[index]["favorite"] ?? []);

            favorites.remove(userId);
            final currentPost = Map<String, dynamic>.from(post[index] as Map);

            post[index] = {...currentPost, "favorite": favorites};

            favoritepost.remove(post[index]);
            // (viewedpost[indexview]["favorite"] as List).remove(userId);
            await PostRepository.instance.removeFavorite(post[index]['_id']);
          } else {
            final favorites = List.from(post[index]["favorite"] ?? []);
            favorites.add(userId);
            post[index]["favorite"] = favorites;
            favoritepost.add(post[index]);
          }
          await PostRepository.instance.saveNewPosts(
            post.cast<Map<String, dynamic>>(),
          );
        }
        if (indexview != -1) {
          final List poster = viewedpost[indexview]['favorite'] ?? [];
          if (status != true && poster.contains(userId)) {
            final favorites = List.from(
              viewedpost[indexview]["favorite"] ?? [],
            );

            favorites.remove(userId);
            final currentPost = Map<String, dynamic>.from(
              viewedpost[indexview] as Map,
            );

            viewedpost[indexview] = {...currentPost, "favorite": favorites};

            favoritepost.remove(viewedpost[indexview]);
            // (viewedpost[indexview]["favorite"] as List).remove(userId);
            await PostRepository.instance.removeFavorite(
              viewedpost[indexview]['_id'],
            );
          } else {
            final favorites = List.from(
              viewedpost[indexview]["favorite"] ?? [],
            );
            favorites.add(userId);
            viewedpost[indexview]["favorite"] = favorites;
            favoritepost.add(viewedpost[indexview]);
          }
          await PostRepository.instance.saveViewedPosts(
            viewedpost.cast<Map<String, dynamic>>(),
          );
          // (viewedpost[indexview]["favorite"] as Set).add(userId);
        }
        if (indexfav != -1) {
          final List poster = favoritepost[indexfav]['favorite'] ?? [];
          if (status != true && poster.contains(userId)) {
            (favoritepost[indexfav]["favorite"] as List).remove(userId);
            favoritepost.remove(favoritepost[indexfav]);
            await PostRepository.instance.removeFavorite(
              favoritepost[indexfav]['_id'],
            );
          } else {
            (favoritepost[indexfav]["favorite"] as List).add(userId);
          }

          // (favoritepost[indexfav]["favorite"] as Set).add(userId);
        }
        final stocks = StockRepository.instance.getAllStocks();

        final stockindex = stocks.indexWhere((e) => e["_id"] == id);
        if (stockindex != -1) {
          final List poster = stocks[stockindex]['favorite'];
          if (status != true && poster.contains(userId)) {
            (stocks[stockindex]["favorite"] as List).remove(userId);
            stocks.remove(stocks[stockindex]);
            await StockRepository.instance.updateStock(
              stocks[stockindex]['_id'],
              stocks[stockindex],
            );
          } else {
            (stocks[stockindex]["favorite"] as List).add(userId);
            await StockRepository.instance.updateStock(
              stocks[stockindex]['_id'],
              stocks[stockindex],
            );
          }
        }

        await PostRepository.instance.clearFavoritePosts();
        await PostRepository.instance.saveFavoritePosts(
          favoritepost.cast<Map<String, dynamic>>(),
        );
      }
    } catch (e) {
      debugPrintStack();
    }
    notifyListeners();
  }

  void filtersdata() {
    final filteredPosts = posts.where((post) {
      final dateStr = post['expiredate'] ?? post['deliverydate'];

      if (dateStr == null) return true;

      final date = DateTime.tryParse(dateStr);
      if (date == null) return true;

      return !date.isBefore(DateTime.now());
    }).toList();
    posts = filteredPosts;
    // notifyListeners();
  }

  Future<void> getSinglePost({
    required String endpoint,
    required String id,
  }) async {
    try {
      setLoading(true);
      isLoading = true;
      PostService postService = PostService();
      filtersdata();
      final response = await postService.getById(
        collectionName: endpoint,
        id: id,
      );

      if (response['status'] == 200) {
        // post = response;
        final List<dynamic> responseData = response['data'] ?? [];

        final filteredData = responseData.where((item) {
          if (item is Map<String, dynamic>) {
            return item['isDeleted'] == false;
          }
          return false;
        }).toList();

        singlepost = List<Map<String, dynamic>>.from(filteredData);
        final existingIndex = posts.indexWhere(
          (item) => item['_id'] == singlepost[0]['_id'],
        );

        if (existingIndex != -1) {
          posts[existingIndex] = singlepost[0];
        } else {
          posts.add(singlepost[0]);
          await StockRepository.instance.deleteStock(singlepost[0]['_id']);
          await StockRepository.instance.saveStocks(
            posts.cast<Map<String, dynamic>>(),
          );
        }
        // allPosts = post.cast<PostModel>();
      } else {
        setError(response.toString());
      }
    } catch (e) {
      debugPrintStack();
      try {
        posts = StockRepository.instance.getAllStocks();
        singlepost = posts.where((item) => item['_id'] == id).toList();
      } catch (e) {
        debugPrintStack();
      }
    }

    setLoading(false);
    isLoading = false;
    notifyListeners();
  }
}

class RecentPostProvider extends BaseProvider {
  bool isLoading = false;
  List<dynamic> post = [];

  Future<void> fetch({
    String? type,
    required String endpoint,
    required String userId,
    String? search,
    String? origin,
    required Map<String, dynamic> filterPayload,
    String? user,
    bool loadMore = false,
  }) async {
    setLoading(true);
    try {
      isLoading = true;

      final payload = filterPayload;
      final response = await PostService().getPosts(
        endpoint: endpoint,
        data: payload,
      );

      if (response['status'] == 200) {
        final List<dynamic> responseData = response['data'][0]['response'];
        if (type == 'RCN') {
          await PostRepository.instance.clearRecentPosts();
        } else if (type == 'Kernel') {
          await PostRepository.instance.clearRecentKernelPosts();
        }
        post = List<Map<String, dynamic>>.from(responseData);
        if (type == 'RCN') {
          await PostRepository.instance.saveRecentPosts(
            post.cast<Map<String, dynamic>>(),
          );
        } else if (type == 'Kernel') {
          await PostRepository.instance.saveRecentKernelPosts(
            post.cast<Map<String, dynamic>>(),
          );
        }
      } else {
        setError(response.statusMessage);
      }
    } catch (e) {
      debugPrintStack();
    }
    if (type == 'RCN') {
      post = PostRepository.instance.getRecentPosts();
    } else if (type == 'Kernel') {
      post = PostRepository.instance.getRecentKernelPosts();
    }
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }
}

class MyPostProvider extends BaseProvider {
  bool isLoading = false;
  bool isFetchingMore = false;
  bool hasMore = true;
  int limit = 30;
  int start = 0;
  List<dynamic> post = [];
  List<dynamic> singlepost = [];

  // Stored so the provider can re-fetch when the offline queue is flushed.
  Map<String, dynamic>? _lastFetchParams;

  MyPostProvider() {
    OfflineQueueService.onQueueFlushed.addListener(_onQueueFlushed);
  }

  @override
  void dispose() {
    OfflineQueueService.onQueueFlushed.removeListener(_onQueueFlushed);
    super.dispose();
  }

  Future<void> _onQueueFlushed() async {
    final p = _lastFetchParams;
    if (p == null) return;
    await _cleanUpOfflinePosts();
    await fetch(
      endpoint: p['endpoint'] as String,
      userId: p['userId'] as String,
      filterPayload: p['filterPayload'] as Map<String, dynamic>,
    );
  }

  /// Remove local-only (offline) posts that have already been uploaded.
  /// A post is considered uploaded when it has an offlineQueueId but is no
  /// longer in the pending queue (i.e. it was sent to the server).
  Future<void> _cleanUpOfflinePosts() async {
    final pendingIds = (await OfflineQueueService.instance.getPendingRequests())
        .map((r) => r.id)
        .toSet();

    final ids = PostRepository.instance.getMyPostsIds();
    final toRemove = <String>[];
    for (final id in ids) {
      final p = PostRepository.instance.getPost(id);
      if (p != null &&
          p.containsKey('offlineQueueId') &&
          !pendingIds.contains(p['offlineQueueId'])) {
        toRemove.add(id);
      }
    }
    for (final id in toRemove) {
      await PostRepository.instance.deletePost(id);
    }
    if (toRemove.isNotEmpty) {
      final remaining = ids.where((id) => !toRemove.contains(id)).toList();
      await PostRepository.instance.clearMyPosts();
      for (final id in remaining) {
        final p = PostRepository.instance.getPost(id);
        if (p != null) await PostRepository.instance.addMyPost(p);
      }
    }
  }

  Future<void> insertLocalPost(Map<String, dynamic> newPost) async {
    if (post.any((element) => element['_id'] == newPost['_id'])) return;

    post.insert(0, newPost);
    await PostRepository.instance.addMyPost(newPost);
    notifyListeners();
  }

  List<String> get origins {
    return post
        .where((e) => e["origin"] != null)
        .map<String>((e) => e["origin"].toString())
        .toSet()
        .toList();
  }

  List<String> get type {
    final data = post
        .where((e) => e["type"] != null)
        .map<String>((e) => e["type"].toString())
        .toSet()
        .toList();
    notifyListeners();
    return data.toSet().toList();
  }

  List<String> get posttype {
    final data = post
        .where((e) => e["post_type"] != null)
        .map<String>(
          (e) => e["post_type"].toString() == "stocks" ? "Sale" : "Purchase",
        )
        .toSet()
        .toList();
    notifyListeners();
    return data.toSet().toList();
  }

  List<String> get grades {
    return post
        .where(
          (e) => e['grade'] != null && e["grade"] != "" && e["grade"] != "RCN",
        )
        .map<String>((e) => e["grade"])
        .toSet()
        .toList();
  }

  List<String> get status {
    return post
        .where((e) => e['status'] != null)
        .map<String>((e) => e['status'].toString())
        .toSet()
        .toList();
  }

  List<Map<String, dynamic>> _queuedPostsFromCache() {
    return PostRepository.instance
        .getAllPosts()
        .where((post) => post.containsKey('offlineQueueId'))
        .toList();
  }

  Future<void> fetch({
    String? type,
    required String endpoint,
    required String userId,
    String? search,
    String? origin,
    required Map<String, dynamic> filterPayload,
    String? user,
    bool loadMore = false,
  }) async {
    _lastFetchParams = {
      'endpoint': endpoint,
      'userId': userId,
      'filterPayload': filterPayload,
    };
    try {
      post = PostRepository.instance.getMyPosts();
      if (post.isEmpty) {
        setLoading(true);
        isLoading = true;
      }
      if (isFetchingMore) return;

      if (loadMore) {
        isFetchingMore = true;
      } else {
        start = 0;
        hasMore = true;
        setLoading(true);
      }

      final payload = {...filterPayload, "start": start, "end": start + limit};

      final response = await PostService().getPosts(
        endpoint: endpoint,
        data: payload,
      );

      if (response['status'] == 200) {
        final List<dynamic> responseData = response['data'][0]['response'];
        final serverPosts = List<Map<String, dynamic>>.from(responseData);

        if (responseData.isEmpty) {
          hasMore = false;
        } else {
          if (loadMore) {
            final merged = [
              ...post,
              ...serverPosts.where(
                (serverPost) => !post.any(
                  (localPost) => localPost['_id'] == serverPost['_id'],
                ),
              ),
            ];
            post = merged;
            await PostRepository.instance.saveMyPosts(
              post.cast<Map<String, dynamic>>(),
            );
          } else {
            // Keep offline-queued posts that haven't been sent yet.
            final pendingIds =
                (await OfflineQueueService.instance.getPendingRequests())
                    .map((r) => r.id)
                    .toSet();
            final stillPending = _queuedPostsFromCache()
                .where((p) => pendingIds.contains(p['offlineQueueId']))
                .toList();

            final merged = [
              ...stillPending,
              ...serverPosts.where(
                (sp) => !stillPending.any((qp) => qp['_id'] == sp['_id']),
              ),
            ];
            post = merged;
            await PostRepository.instance.clearMyPosts();
            await PostRepository.instance.saveMyPosts(
              post.cast<Map<String, dynamic>>(),
            );
          }

          start += limit;
        }
      }
    } catch (e) {
      debugPrintStack();
    }
    post = PostRepository.instance.getMyPosts();
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }

  Future<void> get({
    required String endpoint,
    required String id,
    required Map<String, dynamic> filterPayload,
  }) async {
    setLoading(true);
    ApiDioPostService postService = ApiDioPostService();
    final response = await postService.getdata(
      endpoint: endpoint,
      data: filterPayload,
    );
    if (response['status'] == 200) {
      // post = response;
      final List<dynamic> responseData = response['data'][0]['response'];
      singlepost = List<Map<String, dynamic>>.from(responseData);
      // allPosts = post.cast<PostModel>();
    } else {
      setError(response.toString());
    }
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }

  Future<void> action(String endpoint, bool? status) async {
    ApiDioPostService postService = ApiDioPostService();

    final response = await postService.view(
      endpoint: endpoint,
      data: status == null ? null : {"status": status},
    );
    if (response['status'] == 200) {
      final Map<String, dynamic> responseData = response['data'];
    } else {
      setError(response.toString());
    }
    notifyListeners();
  }

  Future<void> getSinglePost({
    required String endpoint,
    required String id,
  }) async {
    setLoading(true);
    isLoading = true;
    PostService postService = PostService();

    final response = await postService.getById(
      collectionName: endpoint,
      id: id,
    );

    if (response['status'] == 200) {
      // post = response;
      final List<dynamic> responseData = response['data'] ?? [];

      final filteredData = responseData.where((item) {
        if (item is Map<String, dynamic>) {
          return item['isDeleted'] == false;
        }
        return false;
      }).toList();
      singlepost = List<Map<String, dynamic>>.from(filteredData);
      // allPosts = post.cast<PostModel>();
    } else {
      setError(response.toString());
    }
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }
}

class ResponseProvider extends BaseProvider {
  bool isLoading = false;
  List<dynamic> responseForPost = [];

  Map<String, dynamic>? _lastFetchParams;

  ResponseProvider() {
    OfflineQueueService.onQueueFlushed.addListener(_onQueueFlushed);
  }

  @override
  void dispose() {
    OfflineQueueService.onQueueFlushed.removeListener(_onQueueFlushed);
    super.dispose();
  }

  Future<void> _onQueueFlushed() async {
    final p = _lastFetchParams;
    if (p == null) return;
    await getResponseData(
      endpoint: p['endpoint'] as String,
      userId: p['userId'] as String,
      filterPayload: p['filterPayload'] as Map<String, dynamic>,
    );
  }

  Future<void> getResponseData({
    required String endpoint,
    required String userId,
    required Map<String, dynamic> filterPayload,
  }) async {
    _lastFetchParams = {
      'endpoint': endpoint,
      'userId': userId,
      'filterPayload': filterPayload,
    };
    setLoading(true);
    ResponseService responseService = ResponseService();

    final response = await responseService.getResponse(
      endpoint: endpoint,
      data: filterPayload,
    );

    if (response['status'] == 200) {
      final List<dynamic> responseData = response['data'][0]['response'];
      await ResponseRepository.instance.clearResponses();
      responseForPost = List<Map<String, dynamic>>.from(responseData);
      await ResponseRepository.instance.saveResponses(
        responseForPost.cast<Map<String, dynamic>>(),
      );
    } else {
      setError(response.statusMessage);
    }
    responseForPost = ResponseRepository.instance.getResponses();
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }
}

class BiddingPostProvider extends BaseProvider {
  bool isLoading = false;
  bool hasMoreNew = true;
  bool isFetchingMoreNew = false;
  List<dynamic> post = [];

  List<String> get type {
    final data = post
        .where((post) {
          final close = DateTime.parse(
            post['expiredate'] ??
                post["deliverydate"] ??
                "0000-00-00T00:00:00.000Z",
          ).toLocal();
          // Skip invalid or expired
          return close.isAfter(DateTime.now());
        })
        .toList()
        .where((e) => e["type"] != null)
        .map<String>((e) => e["type"].toString())
        .toSet()
        .toList();
    notifyListeners();
    return data.toSet().toList();
  }

  List<String> get posttype {
    final data = post
        .where((post) {
          final close = DateTime.parse(
            post['expiredate'] ??
                post["deliverydate"] ??
                "0000-00-00T00:00:00.000Z",
          ).toLocal();
          // Skip invalid or expired
          return close.isAfter(DateTime.now());
        })
        .toList()
        .where((e) => e["post_type"] != null)
        .map<String>(
          (e) => e["post_type"].toString() == "stocks" ? "Sale" : "Purchase",
        )
        .toSet()
        .toList();
    notifyListeners();
    return data.toSet().toList();
  }

  List<String> get origins {
    return post
        .where((post) {
          final close = DateTime.parse(
            post['expiredate'] ??
                post["deliverydate"] ??
                "0000-00-00T00:00:00.000Z",
          ).toLocal();
          // Skip invalid or expired
          return close.isAfter(DateTime.now());
        })
        .toList()
        .where((e) => e["origin"] != null)
        .map<String>((e) => e["origin"].toString())
        .toSet()
        .toList();
  }

  List<String> get grades {
    return post
        .where((post) {
          final close = DateTime.parse(
            post['expiredate'] ??
                post["deliverydate"] ??
                "0000-00-00T00:00:00.000Z",
          ).toLocal();
          return close.isAfter(DateTime.now());
        })
        .toList()
        .where(
          (e) => e['grade'] != null && e["grade"] != "" && e['grade'] != "RCN",
        )
        .map<String>((e) => e["grade"])
        .toSet()
        .toList();
  }

  int limit = 30;
  int start = 0;
  int startnew = 0;

  List<dynamic> _extractResponseList(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) {
          final payload = first['response'];
          if (payload is List) {
            return payload;
          }
        }
      }
    }
    return const [];
  }

  Future<void> postFetch({
    required String endpoint,
    required String userId,
    required Map<String, dynamic> filterPayload,
    bool loadMore = false,
  }) async {
    setLoading(true);
    isLoading = true;
    if (isFetchingMoreNew) return;

    if (loadMore) {
      isFetchingMoreNew = true;
    } else {
      startnew = 0;
      hasMoreNew = true;
      setLoading(true); // only for first load
    }

    final payload = {
      ...filterPayload,
      "start": startnew,
      "end": startnew + limit,
    };

    try {
      final response = await PostService().getPosts(
        endpoint: endpoint,
        data: payload,
      );

      if (response['status'] == 200) {
        final List<dynamic> responseData = _extractResponseList(response);

        if (loadMore) {
          post.addAll(responseData);
          await PostRepository.instance.saveBiddingPosts(
            post.cast<Map<String, dynamic>>(),
          );
        } else {
          await PostRepository.instance.clearBiddingPosts();
          post = List<dynamic>.from(responseData);
          await PostRepository.instance.saveBiddingPosts(
            post.cast<Map<String, dynamic>>(),
          );
        }

        hasMoreNew = responseData.length >= limit;
        if (responseData.isNotEmpty) {
          startnew += limit;
        }
      } else {
        setError(response.toString());
      }
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      post = PostRepository.instance.getBiddingPosts();
      isFetchingMoreNew = false;
      isLoading = false;
      setLoading(false);
      notifyListeners();
    }
  }
}

class EnquiryProvider extends BaseProvider {
  bool isLoading = false;
  List<dynamic> enquries = [];
  List<dynamic> singlepost = [];

  List<String> get status {
    return enquries
        .where((e) => e['status'] != null)
        .map<String>((e) => e['status'].toString())
        .toSet()
        .toList();
  }

  List<String> get type {
    final data = enquries
        .where((e) => e["type"] != null)
        .map<String>((e) => e["type"].toString())
        .toSet()
        .toList();
    notifyListeners();
    return data.toSet().toList();
  }

  List<String> get posttype {
    final data = enquries
        .where((e) => e["post_type"] != null)
        .map<String>(
          (e) => e["post_type"].toString() == "stocks" ? "Sale" : "Purchase",
        )
        .toSet()
        .toList();
    notifyListeners();
    return data.toSet().toList();
  }

  Future<void> fetch({
    String? type,
    required String endpoint,
    required String userId,
    String? search,
    String? origin,
    required Map<String, dynamic> filterPayload,
    String? user,
  }) async {
    setLoading(true);
    try {
      PostService postService = PostService();

      final response = await postService.getPosts(
        endpoint: endpoint,
        data: filterPayload,
      );

      if (response['status'] == 200) {
        // post = response;
        final List<dynamic> responseData = response['data'][0]['response'];
        await ResponseRepository.instance.clearEnquiries();
        enquries = List<Map<String, dynamic>>.from(responseData);
        await ResponseRepository.instance.saveEnquiries(
          enquries.cast<Map<String, dynamic>>(),
        );
        notifyListeners();
        // allPosts = post.cast<PostModel>();
      } else {
        setError(response.statusMessage);
      }
    } catch (e) {
      debugPrintStack();
    }
    enquries = ResponseRepository.instance.getEnquiries();
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }
}
