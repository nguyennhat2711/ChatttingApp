import 'dart:async';

import 'package:flutter/material.dart';
import 'package:simplechat/models/post_model.dart';
import 'package:simplechat/screens/post/post_detail_screen.dart';
import 'package:simplechat/services/dialog_service.dart';
import 'package:simplechat/services/navigator_service.dart';
import 'package:simplechat/services/network_service.dart';
import 'package:simplechat/utils/dimens.dart';
import 'package:simplechat/utils/params.dart';
import 'package:simplechat/widgets/appbar_widget.dart';
import 'package:simplechat/widgets/empty_widget.dart';
import 'package:simplechat/widgets/textfield_widget.dart';

class MyPostScreen extends StatefulWidget {
  @override
  _MyPostScreenState createState() => _MyPostScreenState();
}

class _MyPostScreenState extends State<MyPostScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  var searchController = TextEditingController();

  List<ExtraPostModel> posts = [];
  List<ExtraPostModel> showPosts = [];

  @override
  void initState() {
    super.initState();

    Timer.run(() {
      _getData();
    });

    searchController.addListener(() {
      _filterData();
    });
  }

  void _getData() async {
    var param = {
      'userid': currentUser.id,
      'limit': '20',
    };
    var resp = await NetworkService(context)
        .ajax('chat_my_post', param, isProgress: true);
    if (resp['ret'] == 10000) {
      posts.clear();
      for (var postJson in resp['result']) {
        ExtraPostModel model = ExtraPostModel.fromMap(postJson);
        posts.add(model);
      }
      posts.sort((b, a) => a.post.regdate.compareTo(b.post.regdate));

      _filterData();
    }
  }

  void _filterData() {
    String search = searchController.text;
    showPosts.clear();
    for (var post in posts) {
      if (post.isContainKey(search)) {
        showPosts.add(post);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: MainBarWidget(
          titleString: 'My Posts',
        ),
        body: Container(
          padding:
              EdgeInsets.symmetric(horizontal: offsetBase, vertical: offsetMd),
          child: Column(
            children: [
              SearchWidget(
                searchController: searchController,
                onClear: () {
                  setState(() {
                    searchController.text = '';
                  });
                },
                onChanged: (value) {},
              ),
              SizedBox(
                height: offsetSm,
              ),
              Expanded(
                child: showPosts.isEmpty
                    ? EmptyWidget(
                        title:
                            'You didn\'t post any feed yet. Please post some feed.',
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: offsetXSm,
                        mainAxisSpacing: offsetXSm,
                        childAspectRatio: 4 / 5,
                        children:
                            List<Widget>.generate(showPosts.length, (index) {
                          return showPosts[index].myItem(action: () {
                            if (showPosts[index].list.isEmpty) {
                              DialogService(context).showSnackbar('This is a text feed so that you can\'t see detail.',
                                  _scaffoldKey, type: SnackBarType.WARING);
                              return;
                            }
                            NavigatorService(context).pushToWidget(
                                screen:
                                    PostDetailScreen(post: showPosts[index]));
                          });
                        }),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
