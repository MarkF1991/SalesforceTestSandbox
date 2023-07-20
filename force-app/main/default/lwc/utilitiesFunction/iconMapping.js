const iconNameMapping = [
    { name: "bug_report", category: "attack" },
    { name: "lock", category: "v" },
    { name: "lock", category: "lock" },
    { name: "warning", category: "alert" },
    { name: "error", category: "error" },
    { name: "check_circle", category: "clear" },
    { name: "gps_fixed", category: "target" },
    { name: "code", category: "code" },
    { name: "videogame_asset", category: "gaming" },
    { name: "desktop_windows", category: "desktop" },
    { name: "laptop", category: "chromebook" },
    { name: "laptop", category: "laptop" },
    { name: "smartphone", category: "smartphone" },
    { name: "phone_iphone", category: "iPhone" },
    { name: "phone_android", category: "Android Phone" },
    { name: "tablet", category: "tablet" },
    { name: "device_unknown", category: "unknown" },
    { name: "memory", category: "informationTechnology" },
    { name: "ballot", category: "newsMedia" },
    { name: "insert_drive_file", category: "fileSharing" },
    { name: "cast_connected", category: "reference" },
    { name: "forum", category: "instantMessaging" },
    { name: "supervised_user_circle", category: "socialMedia" },
    { name: "supervised_user_circle", category: "application" },
    { name: "thumb_up", category: "thumbUp" },
    { name: "thumb_up", category: "success" },
    { name: "thumb_down", category: "thumbDown" },
    { name: "public", category: "content" },
    { name: "public", category: "website" },
    { name: "folder", category: "categories" },
    { name: "folder", category: "category" },
    { name: "signal_wifi_4_bar", category: "connections" },
    { name: "security", category: "security" },
    { name: "security", category: "safety" },
    { name: "devices_other", category: "devices" },
    { name: "devices_other", category: "device" }, //css has this interchangable devices and device. Therefore the iconname can do the same.
    { name: "people", category: "users" },
    { name: "people", category: "user" }, //css has this interchangable devices and device. Therefore the iconname can do the same.
    // {name:'signal_wifi_1_bar', category: 'poor'},
    // {name:'signal_wifi_2_bar', category: 'good'},
    //{name:'signal_wifi_3_bar', category: 'veryGood'},
    { name: "sentiment_very_dissatisfied", category: "veryBad" },
    { name: "sentiment_dissatisfied", category: "bad" },
    { name: "sentiment_satisfied", category: "good" },
    { name: "sentiment_very_satisfied", category: "veryGood" },
    { name: "apps", category: "Apps" },
    { name: "desktop_mac", category: "Computer" },
    { name: "tablet_android", category: "Android Tablet" },
    { name: "tablet_mac", category: "iPad" },
    // { name: "tablet_android", category: "Tablet" },
    { name: "phone_iphone", category: "Cell Phone" },
    { name: "local_printshop", category: "Other" },
    { name: "arrow_drop_up", category: "up" },
    { name: "arrow_drop_down", category: "down" },
    { name: "remove", category: "neutral" },
    {
      category: "Abortion",
      name: "pregnant_woman",
      color: "#8199AF"
    },
    {
      category: "Advocacy Organizations",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Alcohol",
      name: "local_bar",
      color: "#8199AF"
    },
    {
      category: "Alternative Beliefs",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Dating",
      name: "wc",
      color: "#8199AF"
    },
    {
      category: "Gambling",
      name: "attach_money",
      color: "#8199AF"
    },
    {
      category: "Lingerie and Swimsuit",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Marijuana",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Nudity and Risque",
      name: "visibility_off",
      color: "#8199AF"
    },
    {
      category: "Other Adult Materials",
      name: "visibility_off",
      color: "#8199AF"
    },
    {
      category: "Pornography",
      name: "visibility_off",
      color: "#8199AF"
    },
    {
      category: "Sex Education",
      name: "child_care",
      color: "#8199AF"
    },
    {
      category: "Sports Hunting and War Games",
      name: "whatshot",
      color: "#8199AF"
    },
    {
      category: "Tobacco",
      name: "smoke_free",
      color: "#8199AF"
    },
    {
      category: "Weapons (Sales)",
      name: "whatshot",
      color: "#8199AF"
    },
    {
      category: "File Sharing and Storage",
      name: "insert_drive_file",
      color: "#8199AF"
    },
    {
      category: "Freeware and Software Downloads",
      name: "save_alt",
      color: "#8199AF"
    },
    {
      category: "Internet Radio and TV",
      name: "radio",
      color: "#8199AF"
    },
    {
      category: "Internet Telephony",
      name: "call",
      color: "#8199AF"
    },
    {
      category: "Peer-to-peer File Sharing",
      name: "swap_horiz",
      color: "#8199AF"
    },
    {
      category: "Streaming Media and Download",
      name: "cloud_download",
      color: "#8199AF"
    },
    {
      category: "Armed Forces",
      name: "whatshot",
      color: "#8199AF"
    },
    {
      category: "Business",
      name: "domain",
      color: "#8199AF"
    },
    {
      category: "Charitable Organizations",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Finance and Banking",
      name: "attach_money",
      color: "#8199AF"
    },
    {
      category: "General Organizations",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Government and Legal Organizations",
      name: "account_balance",
      color: "#8199AF"
    },
    {
      category: "Information Technology",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Information and Computer Security",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Online Meeting",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Remote Access",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Search Engines and Portals",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Secure Websites",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Web Analytics",
      name: "bar_chart",
      color: "#8199AF"
    },
    {
      category: "Web Hosting",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Web-based Applications",
      name: "language",
      color: "#8199AF"
    },
    {
      category: "Advertising",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Arts and Culture",
      name: "color_lens",
      color: "#8199AF"
    },
    {
      category: "Auction",
      name: "gavel",
      color: "#8199AF"
    },
    {
      category: "Brokerage and Trading",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Child Education",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Content Servers",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Digital Postcards",
      name: "insert_photo",
      color: "#8199AF"
    },
    {
      category: "Domain Parking",
      name: "local_parking",
      color: "#8199AF"
    },
    {
      category: "Dynamic Content",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Education",
      name: "school",
      color: "#8199AF"
    },
    {
      category: "Entertainment",
      name: "theaters",
      color: "#8199AF"
    },
    {
      category: "Folklore",
      name: "adb",
      color: "#8199AF"
    },
    {
      category: "Games",
      name: "videogame_asset",
      color: "#8199AF"
    },
    {
      category: "Global Religion",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Health and Wellness",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Instant Messaging",
      name: "chat",
      color: "#8199AF"
    },
    {
      category: "Job Search",
      name: "work",
      color: "#8199AF"
    },
    {
      category: "Meaningless Content",
      name: "not_listed_location",
      color: "#8199AF"
    },
    {
      category: "Medicine",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "News and Media",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Newsgroups and Message Boards",
      name: "question_answer",
      color: "#8199AF"
    },
    {
      category: "Personal Privacy",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Personal Vehicles",
      name: "directions_car",
      color: "#8199AF"
    },
    {
      category: "Personal Websites and Blogs",
      name: "person",
      color: "#8199AF"
    },
    {
      category: "Political Organizations",
      name: "folder",
      color: "#8199AF"
    },
    {
      category: "Real Estate",
      name: "home",
      color: "#8199AF"
    },
    {
      category: "Reference",
      name: "map",
      color: "#8199AF"
    },
    {
      category: "Restaurant and Dining",
      name: "restaurant",
      color: "#8199AF"
    },
    {
      category: "Shopping",
      name: "shopping_cart",
      color: "#8199AF"
    },
    {
      category: "Social Networking",
      name: "thumbs_up_down",
      color: "#8199AF"
    },
    {
      category: "Society and Lifestyles",
      name: "local_florist",
      color: "#8199AF"
    },
    {
      category: "Sports",
      name: "rowing",
      color: "#8199AF"
    },
    {
      category: "Travel",
      name: "flight",
      color: "#8199AF"
    },
    {
      category: "Web Chat",
      name: "chat_bubble",
      color: "#8199AF"
    },
    {
      category: "Web-based Email",
      name: "email",
      color: "#8199AF"
    },
    {
      category: "Child Abuse",
      name: "visibility_off",
      color: "#F5675B"
    },
    {
      category: "Discrimination",
      name: "visibility_off",
      color: "#F5675B"
    },
    {
      category: "Drug Abuse",
      name: "visibility_off",
      color: "#F5675B"
    },
    {
      category: "Explicit Violence",
      name: "visibility_off",
      color: "#F5675B"
    },
    {
      category: "Extremist Groups",
      name: "visibility_off",
      color: "#F5675B"
    },
    {
      category: "Hacking",
      name: "code",
      color: "#8199AF"
    },
    {
      category: "Illegal or Unethical",
      name: "visibility_off",
      color: "#F5675B"
    },
    {
      category: "Plagiarism",
      name: "file_copy",
      color: "#8199AF"
    },
    {
      category: "Proxy Avoidance",
      name: "vpn_lock",
      color: "#8199AF"
    },
    {
      category: "Dynamic DNS",
      name: "code",
      color: "#8199AF"
    },
    {
      category: "Malicious Websites",
      name: "code",
      color: "#8199AF"
    },
    {
      category: "Newly Observed Domain",
      name: "fiber_new",
      color: "#8199AF"
    },
    {
      category: "Newly Registered Domain",
      name: "fiber_new",
      color: "#8199AF"
    },
    {
      category: "Phishing",
      name: "visibility_off",
      color: "#8199AF"
    },
    {
      category: "Spam URLs",
      name: "visibility_off",
      color: "#8199AF"
    }
  ];
export {
    iconNameMapping
}