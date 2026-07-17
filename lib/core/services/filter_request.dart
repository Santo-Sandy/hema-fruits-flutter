class FilterRequest {
  final String? userId;
  final String? user;
  final String? type;

  FilterRequest({this.userId, this.user, this.type});

  Map<String, dynamic> getBuyerPost({
    String? role,
    String? type,
    String? origin,
    String? search,
    String? fav,
    String? view,
    String? fromDate,
    String? toDate,
    String excludeColumn = "userId",
  }) {
    final now = DateTime.now().toUtc();

    // subtract buffer (important)
    final safeNow = now.subtract(const Duration(minutes: 1));
    List<Map<String, dynamic>> andConditions = [
      {"column": excludeColumn, "operator": "NOTEQUAL", "value": userId},
      {"column": "blocked_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "blocker_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "isDeleted", "operator": "EQUALS", "value": false},
      {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
      // {
      //   "column": "expiredate",
      //   "operator": "GREATERTHANOREQUAL",
      //   "type": "date",
      //   "value": DateTime.utc(
      //     safeNow.year,
      //     safeNow.month,
      //     safeNow.day,
      //     safeNow.hour,
      //     safeNow.minute,
      //     safeNow.second,
      //   ).toIso8601String(),
      // },
      // {
      //   "column": "expiredate",
      //   "operator": "GREATERTHANOREQUAL",
      //   "type": "date",
      //   "value": DateTime.now().toUtc().toIso8601String(),
      // },
    ];

    if (fav != null) {
      andConditions.add({
        "column": "favorite",
        "operator": "EQUALS",
        "value": userId,
      });
    } else if (view != null) {
      andConditions.add({
        "column": "viewed",
        "operator": "EQUALS",
        "value": userId,
      });
    } else {
      andConditions.add({
        "column": "viewed",
        "operator": "NOTEQUAL",
        "value": userId,
      });
    }
    if (role != null) {
      andConditions.add({
        "column": "post_type",
        "operator": "EQUALS",
        "value": role,
      });
    }
    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }

    if (origin != null) {
      andConditions.add({
        "column": "origin",
        "operator": "EQUALS",
        "value": origin,
      });
    }

    if (fromDate != null && toDate != null) {
      andConditions.addAll([
        {
          "column": "endDate",
          "operator": "GREATERTHANOREQUAL",
          "type": "date",
          "value": fromDate,
        },
        {
          "column": "endDate",
          "operator": "LESSTHANOREQUAL",
          "type": "date",
          "value": toDate,
        },
      ]);
    }

    List<Map<String, dynamic>> filter = [
      {"clause": "AND", "conditions": andConditions},
    ];

    if (search != null && search.isNotEmpty) {
      filter.add({
        "clause": "OR",
        "conditions": [
          {"column": "merchantname", "operator": "CONTAINS", "value": search},
        ],
      });
    }

    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      "filter": filter,
    };
  }

  Map<String, dynamic> getSellerPost({
    String? type,
    String? origin,
    String? search,
    String? fav,
    String? view,
    String? fromDate,
    String? toDate,
  }) {
    List<Map<String, dynamic>> andConditions = [
      {"column": "buyerId", "operator": "NOTEQUAL", "value": userId},
      {"column": "blocked_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "blocker_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "isDeleted", "operator": "EQUALS", "value": false},
      {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
      // {
      //   "column": "deliverydate",
      //   "operator": "GREATERTHANOREQUAL",
      //   "type": "date",
      //   "value": DateTime.now().toUtc().toIso8601String(),
      // },
    ];

    if (fav != null) {
      andConditions.add({
        "column": "favorite",
        "operator": "EQUALS",
        "value": userId,
      });
    } else if (view != null) {
      andConditions.add({
        "column": "viewed",
        "operator": "EQUALS",
        "value": userId,
      });
    } else {
      andConditions.add({
        "column": "viewed",
        "operator": "NOTEQUAL",
        "value": userId,
      });
    }

    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }

    if (origin != null) {
      andConditions.add({
        "column": "origin",
        "operator": "EQUALS",
        "value": origin,
      });
    }

    if (fromDate != null && toDate != null) {
      andConditions.addAll([
        {
          "column": "deliverydate",
          "operator": "GREATERTHANOREQUAL",
          "type": "date",
          "value": fromDate,
        },
        {
          "column": "deliverydate",
          "operator": "LESSTHANOREQUAL",
          "type": "date",
          "value": toDate,
        },
      ]);
    }

    List<Map<String, dynamic>> filter = [
      {"clause": "AND", "conditions": andConditions},
    ];

    if (search != null && search.isNotEmpty) {
      filter.add({
        "clause": "OR",
        "conditions": [
          {"column": "user_name", "operator": "CONTAINS", "value": search},
        ],
      });
    }

    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      "filterParams": [
        {
          "parmasName": "user_ref_id",
          "parmsDataType": "string",
          "paramsValue": userId,
        },
      ],
      "filter": filter,
    };
  }

  Map<String, dynamic> getBiddingBuyerPost({
    String? type,
    String? origin,
    String? grade,
    String? posttype,

    String excludeColumn = "userId",
  }) {
    List<Map<String, dynamic>> andConditions = [
      {"column": excludeColumn, "operator": "NOTEQUAL", "value": userId},
      {"column": "isDeleted", "operator": "EQUALS", "value": false},
      {"column": "blocked_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "blocker_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
      {"column": "negotiateprice", "operator": "NOTEQUAL", "value": false},
      {"column": "lowerbit", "operator": "NOTEQUAL", "value": false},
      {
        "column": "endDate",
        "operator": "GREATERTHANOREQUAL",
        "type": "date",
        "value": DateTime.now().toUtc().toIso8601String(),
      },
    ];

    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }
    if (posttype != null) {
      andConditions.add({
        "column": "post_type",
        "operator": "EQUALS",
        "value": posttype,
      });
    }
    if (origin != null) {
      andConditions.add({
        "column": "origin",
        "operator": "EQUALS",
        "value": origin,
      });
    }

    List<Map<String, dynamic>> filter = [
      {"clause": "AND", "conditions": andConditions},
      // {
      //   "clause": "OR",
      //   "conditions": [
      //     {
      //       "column": "expiredate",
      //       "operator": "GREATERTHANOREQUAL",
      //       "type": "date",
      //       "value": DateTime.now().toUtc().toIso8601String(),
      //     },
      //     {
      //       "column": "deliverydate",
      //       "operator": "GREATERTHANOREQUAL",
      //       "type": "date",
      //       "value": DateTime.now().toUtc().toIso8601String(),
      //     },
      //   ],
      // },
    ];

    if (grade != null && grade.isNotEmpty) {
      filter.add({
        "clause": "OR",
        "conditions": [
          {"column": "grade", "operator": "CONTAINS", "value": grade},
        ],
      });
    }

    return {
      "sort": [
        {"sort": "asc", "colId": "endDate"},
      ],
      "filter": filter,
    };
  }

  Map<String, dynamic> getBiddingSellerPost({
    String? type,
    String? origin,
    String? grade,
  }) {
    List<Map<String, dynamic>> andConditions = [
      {"column": "buyerId", "operator": "NOTEQUAL", "value": userId},
      {"column": "isDeleted", "operator": "EQUALS", "value": false},
      {"column": "blocked_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "blocker_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "lowerbit", "operator": "EQUALS", "value": true},
      {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
      // {
      //   "column": "deliverydate",
      //   "operator": "GREATERTHANOREQUAL",
      //   "type": "date",
      //   "value": DateTime.now().toUtc().toIso8601String(),
      // },
    ];

    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }

    if (origin != null) {
      andConditions.add({
        "column": "origin",
        "operator": "EQUALS",
        "value": origin,
      });
    }

    List<Map<String, dynamic>> filter = [
      {"clause": "AND", "conditions": andConditions},
    ];

    if (grade != null && grade.isNotEmpty) {
      filter.add({
        "clause": "OR",
        "conditions": [
          {"column": "grade", "operator": "CONTAINS", "value": grade},
        ],
      });
    }

    return {
      "sort": [
        {"sort": "asc", "colId": "deliverydate"},
      ],
      "filterParams": [
        {
          "parmasName": "user_ref_id",
          "parmsDataType": "string",
          "paramsValue": userId,
        },
      ],
      "filter": filter,
    };
  }

  Map<String, dynamic> getuserprofile() {
    return {
      "filter": [
        {
          "clause": "AND",
          "conditions": [
            {"column": "_id", "operator": "EQUALS", "value": userId},
          ],
        },
      ],
    };
  }

  Map<String, dynamic> getblockeduser() {
    return {
      "filter": [
        {
          "clause": "AND",
          "conditions": [
            {"column": "userId", "operator": "EQUALS", "value": userId},
          ],
        },
      ],
    };
  }

  Map<String, dynamic> getBuyerResponse({
    String? type,
    String? grade,
    String? origin,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) {
    // List<Map<String, dynamic>> filterParams = [
    //   {
    //     "parmasName": "user_ref_id",
    //     "parmsDataType": "string",
    //     "paramsValue": {'\$ne': userId},
    //   },
    // ];

    // if (search != null && search.isNotEmpty) {
    //   filterParams.add({
    //     "parmasName": "query_name",
    //     "parmsDataType": "string",
    //     "paramsValue": search,
    //   });
    // } else {
    //   filterParams.add({
    //     "parmasName": "query_name",
    //     "parmsDataType": "string",
    //     "paramsValue": '',
    //   });
    // }

    List<Map<String, dynamic>> andConditions = [
      {"column": "buyerId", "operator": "NOTEQUAL", "value": userId},
      {"column": "merchantId", "operator": "EQUALS", "value": userId},
      {"column": "blocked_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "blocker_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
      {"column": "product_isdeleted", "operator": "EQUALS", "value": false},
    ];

    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }

    if (status != null) {
      andConditions.add({
        "column": "status",
        "operator": "EQUALS",
        "value": status.toLowerCase(),
      });
    }

    if (search != null && search.isNotEmpty) {
      andConditions.add({
        "clause": "OR",
        "conditions": [
          {"column": "buyer_name", "operator": "CONTAINS", "value": search},
        ],
      });
    }

    if (fromDate != null && toDate != null) {
      andConditions.addAll([
        {
          "column": "created_on",
          "operator": "GREATERTHANOREQUAL",
          "type": "date",
          "value": fromDate,
        },
        {
          "column": "created_on",
          "operator": "LESSTHANOREQUAL",
          "type": "date",
          "value": toDate,
        },
      ]);
    }

    // if (andConditions.isEmpty) {
    //   return {"filterParams": filterParams};
    // }

    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      // "filterParams": filterParams,
      "filter": [
        {"clause": "AND", "conditions": andConditions},
      ],
    };
  }

  Map<String, dynamic> getSellerResponse({
    String? type,
    String? grade,
    String? posttype,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) {
    List<Map<String, dynamic>> andConditions = [
      {"column": "buyerId", "operator": "EQUALS", "value": userId},
      {"column": "merchantId", "operator": "EQUALS", "value": userId},
      {"column": "blocked_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "blocker_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "isDeleted", "operator": "EQUALS", "value": false},
    ];

    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }

    if (posttype != null) {
      andConditions.add({
        "column": "post_type",
        "operator": "EQUALS",
        "value": posttype,
      });
    }

    if (status != null) {
      andConditions.add({
        "column": "status",
        "operator": "EQUALS",
        "value": status,
      });
    }
    if (grade != null) {
      andConditions.add({
        "column": "grade",
        "operator": "EQUALS",
        "value": grade,
      });
    }

    if (fromDate != null && toDate != null) {
      andConditions.addAll([
        {
          "column": "created_on",
          "operator": "GREATERTHANOREQUAL",
          "type": "date",
          "value": fromDate,
        },
        {
          "column": "created_on",
          "operator": "LESSTHANOREQUAL",
          "type": "date",
          "value": toDate,
        },
      ]);
    }

    List<Map<String, dynamic>> filter = [
      {"clause": "AND", "conditions": andConditions},
    ];

    if (search != null && search.isNotEmpty) {
      filter.add({
        "clause": "OR",
        "conditions": [
          {"column": "merchantname", "operator": "CONTAINS", "value": search},
        ],
      });
    }

    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      "filter": filter,
    };
  }

  Map<String, dynamic> getRequirement() {
    return {
      "filter": [
        {
          "clause": "AND",
          "conditions": [
            {"column": user, "operator": "EQUALS", "value": userId},
            {"column": "isDeleted", "operator": "EQUALS", "value": false},
            {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
          ],
        },
      ],
    };
  }

  Map<String, dynamic> getMyRequirementPost({
    String? type,
    String? status,
    String? grade,
    String? posttype,
    String? origin,
    String? fromDate,
    String? toDate,
  }) {
    List<Map<String, dynamic>> andConditions = [
      {"column": "userId", "operator": "EQUALS", "value": userId},
      {"column": "isDeleted", "operator": "EQUALS", "value": false},
    ];

    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }

    if (posttype != null) {
      andConditions.add({
        "column": "post_type",
        "operator": "EQUALS",
        "value": posttype,
      });
    }
    if (status != null) {
      andConditions.add({
        "column": "status",
        "operator": "EQUALS",
        "value": status,
      });
    }
    if (origin != null) {
      andConditions.add({
        "column": "origin",
        "operator": "EQUALS",
        "value": origin,
      });
    }
    if (grade != null) {
      andConditions.add({
        "column": "grade",
        "operator": "EQUALS",
        "value": grade,
      });
    }

    if (fromDate != null && toDate != null) {
      andConditions.addAll([
        {
          "column": "created_on",
          "operator": "GREATERTHANOREQUAL",
          "type": "date",
          "value": fromDate,
        },
        {
          "column": "created_on",
          "operator": "LESSTHANOREQUAL",
          "type": "date",
          "value": toDate,
        },
      ]);
    }

    List<Map<String, dynamic>> filter = [
      {"clause": "AND", "conditions": andConditions},
    ];

    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      "filter": filter,
    };
  }

  Map<String, dynamic> getMyStockPost({
    String? type,
    String? grade,
    String? origin,
    String? fromDate,
    String? toDate,
  }) {
    List<Map<String, dynamic>> andConditions = [
      {"column": user, "operator": "EQUALS", "value": userId},
      {"column": "isDeleted", "operator": "EQUALS", "value": false},
      {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
    ];

    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }

    if (grade != null) {
      andConditions.add({
        "column": "grade",
        "operator": "EQUALS",
        "value": grade,
      });
    }

    if (origin != null) {
      andConditions.add({
        "column": "origin",
        "operator": "EQUALS",
        "value": origin,
      });
    }

    if (fromDate != null && toDate != null) {
      andConditions.addAll([
        {
          "column": "created_on",
          "operator": "GREATERTHANOREQUAL",
          "type": "date",
          "value": fromDate,
        },
        {
          "column": "created_on",
          "operator": "LESSTHANOREQUAL",
          "type": "date",
          "value": toDate,
        },
      ]);
    }

    List<Map<String, dynamic>> filter = [
      {"clause": "AND", "conditions": andConditions},
    ];

    if (type != null ||
        grade != null ||
        (fromDate != null && toDate != null) ||
        origin != null) {
      return {
        "filter": filter,
        "sort": [
          {"sort": "desc", "colId": "created_at"},
        ],
      };
    }
    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      "filter": filter,
    };
  }

  Map<String, dynamic> getdashboard() {
    return {
      "filter": [
        {
          "clause": "AND",
          "conditions": [
            {"column": 'userid', "operator": "EQUALS", "value": userId},
            {"column": "type", "operator": "EQUALS", "value": type},
            {"column": "isDeleted", "operator": "EQUALS", "value": false},
            {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
          ],
        },
      ],
    };
  }

  Map<String, dynamic> getPostByCategory() {
    return {
      'filterParams': [
        {
          "parmasName": "user_ref_id",
          "parmsDataType": "string",
          "paramsValue": userId,
        },

        {"parmasName": "type", "parmsDataType": "string", "paramsValue": type},
      ],
    };
  }

  Map<String, dynamic> getbiddingResponse() {
    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      "filterParams": [
        {
          "parmasName": "user_ref_id",
          "parmsDataType": "string",
          "paramsValue": userId,
        },
        null,
        {
          "parmasName": "query_name",
          "parmsDataType": "string",
          "paramsValue": "",
        },
      ],
      "filter": [
        {
          "clause": "AND",
          "conditions": [
            {"column": "type", "operator": "EQUALS", "value": "RCN"},
          ],
        },
      ],
    };
  }

  Map<String, dynamic> getBuyerEnquiry({
    String? type,
    String? posttype,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) {
    List<Map<String, dynamic>> andConditions = [
      {'column': "userId", 'operator': "EQUALS", 'value': userId},
      {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
      {"column": "blockedres_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "blockerres_ids", "operator": "NOTEQUAL", "value": userId},
    ];

    if (search != null) {
      andConditions.add({
        "column": "merchantname",
        "operator": "CONTAINS",
        "value": search,
      });
    }

    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }

    if (posttype != null) {
      andConditions.add({
        "column": "post_type",
        "operator": "EQUALS",
        "value": posttype,
      });
    }

    if (status != null) {
      andConditions.add({
        "column": "status",
        "operator": "EQUALS",
        "value": status.toLowerCase(),
      });
    }

    if (fromDate != null && toDate != null) {
      andConditions.addAll([
        {
          "column": "created_on",
          "operator": "GREATERTHANOREQUAL",
          "type": "date",
          "value": fromDate,
        },
        {
          "column": "created_on",
          "operator": "LESSTHANOREQUAL",
          "type": "date",
          "value": toDate,
        },
      ]);
    }

    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      "filter": [
        {"clause": "AND", "conditions": andConditions},
      ],
    };
  }

  Map<String, dynamic> getSellerEnquiry({
    String? type,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) {
    List<Map<String, dynamic>> andConditions = [
      {"column": "merchantId", "operator": "EQUALS", "value": userId},
      {"column": "blockedres_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "blockerres_ids", "operator": "NOTEQUAL", "value": userId},
      {"column": "isDeleted", "operator": "EQUALS", "value": false},
      //{"column": "status", "operator": "NOTEQUAL", "value": "new"},
    ];

    if (type != null) {
      andConditions.add({
        "column": "type",
        "operator": "EQUALS",
        "value": type,
      });
    }

    if (status != null) {
      andConditions.add({
        "column": "status",
        "operator": "EQUALS",
        "value": status.toLowerCase(),
      });
    }

    if (fromDate != null && toDate != null) {
      andConditions.addAll([
        {
          "column": "created_on",
          "operator": "GREATERTHANOREQUAL",
          "type": "date",
          "value": fromDate,
        },
        {
          "column": "created_on",
          "operator": "LESSTHANOREQUAL",
          "type": "date",
          "value": toDate,
        },
      ]);
    }

    List<Map<String, dynamic>> filter = [
      {"clause": "AND", "conditions": andConditions},
    ];

    if (search != null && search.isNotEmpty) {
      filter.add({
        "clause": "OR",
        "conditions": [
          {"column": "name", "operator": "CONTAINS", "value": search},
        ],
      });
    }

    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      "filter": filter,
    };
  }

  Map<String, dynamic> getNotification() {
    return {
      "sort": [
        {"sort": "desc", "colId": "created_on"},
      ],
      "filter": [
        {
          "clause": "AND",
          "conditions": [
            {"column": "receiverId", "operator": "EQUALS", "value": userId},
            {"column": "blocked_ids", "operator": "NOTEQUAL", "value": userId},
            {"column": "blocker_ids", "operator": "NOTEQUAL", "value": userId},
            {"column": "isread", "operator": "EQUALS", "value": false},
          ],
        },
      ],
    };
  }
}
