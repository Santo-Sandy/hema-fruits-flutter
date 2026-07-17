class FiltersDynamic {
  static List<dynamic> getFilters(String exludedfilter, List<dynamic> filters) {
    List<dynamic> origins = [];
    List<dynamic> grades = [];
    List<dynamic> productTypes = [];
    List<dynamic> postTypes = [];
    if (exludedfilter != "origins") {
      origins = ["All", ...filters[0]];
    }
    if (exludedfilter != "grades") {
      grades = ["All", ...filters[1]];
    }
    if (exludedfilter != "productTypes") {
      productTypes = ["All Listings", ...filters[2]];
    }
    if (exludedfilter != "postTypes") {
      postTypes = ["All", ...filters[3]];
    }
    return [origins, grades, productTypes, postTypes];
  }
}
