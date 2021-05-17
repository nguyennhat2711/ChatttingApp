import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simplechat/main.dart';
import 'package:simplechat/models/media_model.dart';
import 'package:simplechat/models/post_model.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/screens/post/post_feed_screen.dart';
import 'package:simplechat/services/dialog_service.dart';
import 'package:simplechat/services/image_service.dart';
import 'package:simplechat/services/load_service.dart';
import 'package:simplechat/services/navigator_service.dart';
import 'package:simplechat/services/network_service.dart';
import 'package:simplechat/services/string_service.dart';
import 'package:simplechat/utils/colors.dart';
import 'package:simplechat/utils/constants.dart';
import 'package:simplechat/utils/dimens.dart';
import 'package:simplechat/utils/params.dart';
import 'package:simplechat/utils/themes.dart';
import 'package:simplechat/widgets/appbar_widget.dart';
import 'package:simplechat/widgets/common_widget.dart';
import 'package:simplechat/widgets/label_widget.dart';
import 'package:video_player/video_player.dart';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  VideoPlayerController _videoController;
  var _commentController = TextEditingController();
  var _tagController = TextEditingController();

  List<MediaModel> models = [];
  List<String> tags = [];
  List<UserModel> users = [];


  @override
  void initState() {
    super.initState();

    _getData();
  }

  void _getData() async {
    var param = {
      'userid': currentUser.id,
    };
    var resp = await NetworkService(context)
        .ajax('chat_follow_user', param, isProgress: false);
    if (resp['ret'] == 10000) {
      users.clear();
      for (var json in resp['result']) {
        UserModel userModel = UserModel.fromMap(json);
        users.add(userModel);
      }
    }
  }

  _imgPicker(ImageSource source) async {
    PickedFile image = await ImagePicker().getImage(
        source: source, imageQuality: 50, maxWidth: 4000, maxHeight: 4000);

    String base64Thumbnail = await ImageService()
        .getThumbnailBase64FromImage(File(image.path), width: 320, height: 320);

    MediaModel mediaModel = MediaModel(
      userid: currentUser.id,
      kind: 'POST',
      type: 'IMAGE',
      thumbnail: base64Thumbnail,
      file: File(image.path),
      other: '',
    );

    setState(() {
      models.add(mediaModel);
    });
  }

  _vidPicker(ImageSource source) async {
    PickedFile video = await ImagePicker().getVideo(source: source);

    String base64Thumbnail = await ImageService()
        .getThumbnailBase64FromVideo(File(video.path), width: 320, height: 320);

    MediaModel mediaModel = MediaModel(
      userid: currentUser.id,
      kind: 'POST',
      type: 'VIDEO',
      thumbnail: base64Thumbnail,
      file: File(video.path),
      other: '',
    );

    setState(() {
      models.add(mediaModel);
    });
  }

  @override
  void dispose() {
    if (_videoController != null) {
      _videoController.dispose();
    }
    if (_commentController != null) {
      _commentController.dispose();
    }
    if (_tagController != null) {
      _tagController.dispose();
    }

    super.dispose();
  }

  Widget addMedalWidget() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: Radius.circular(offsetBase),
      dashPattern: [8, 4],
      strokeWidth: 2,
      color: Colors.blueGrey,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(offsetBase)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_add.svg',
                width: 24.0,
                height: 24.0,
                color: Colors.blueGrey,
              ),
              SizedBox(
                height: offsetSm,
              ),
              Text(
                'Add Media',
                style:
                    semiBold.copyWith(fontSize: fontMd, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget emptyWidget() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: Radius.circular(offsetBase),
      dashPattern: [8, 4],
      strokeWidth: 2,
      color: Colors.blueGrey,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(offsetBase)),
        ),
      ),
    );
  }

  void upload() async {
    String comment = _commentController.text;
    if (comment.isEmpty && models.isEmpty) {
      DialogService(context).showSnackbar(
          'The post data is empty.', _scaffoldKey,
          type: SnackBarType.WARING);
      return;
    }
    PostModel model = PostModel();
    model.userid = currentUser.id;
    model.content = comment;
    model.regdate = StringService.getCurrentUTCTime();
    model.tag = tags.isNotEmpty ? tags.join(',') : '';
    model.other = '';
    LoadService().showLoading(context);

    var respPost = await model.upload();
    for (var media in models) {
      media.mediaid = '${respPost['result']}';
      media.regdate = StringService.getCurrentUTCTime();
      media.content = '';
      await media.upload();
    }

    LoadService().hideLoading(context);

    for (var user in users) {
      socketService.addPost(user.id);
    }

    DialogService(context).showSnackbar('Successful upload post', _scaffoldKey,
        dismiss: () {
      Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: MainBarWidget(
          titleString: 'Add Post',
          actions: [
            IconButton(
                icon: Icon(Icons.upload_rounded),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  upload();
                })
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: offsetBase, vertical: offsetMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: offsetBase),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Comment',
                        style: semiBold.copyWith(fontSize: fontMd),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _commentController.text = '';
                          });
                        },
                        child: Text(
                          'Clear',
                          style: semiBold.copyWith(
                            fontSize: fontMd,
                            color: Colors.red,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: offsetBase,
                ),
                Container(
                  padding: EdgeInsets.all(offsetBase),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(offsetBase)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 0,
                        blurRadius: 1,
                        offset: Offset(0, 0), // changes position of shadow
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _commentController,
                    minLines: 5,
                    maxLines: 7,
                    keyboardType: TextInputType.multiline,
                    style: mediumText.copyWith(fontSize: fontBase),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Add Story Comment',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(
                  height: offsetLg,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: offsetBase),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Tags',
                        style: semiBold.copyWith(fontSize: fontMd),
                      ),
                      InkWell(
                          onTap: () {
                            DialogService(context).showCustomDialog(
                                titleWidget: Text(
                                  'Add Tag',
                                  style: semiBold.copyWith(fontSize: fontMd),
                                ),
                                bodyWidget: Container(
                                  color: Colors.white,
                                  padding: EdgeInsets.all(offsetBase),
                                  child: TextField(
                                    controller: _tagController,
                                    style:
                                        mediumText.copyWith(fontSize: fontBase),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Add Tag',
                                      focusedBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: primaryColor)),
                                      border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.blueGrey)),
                                      errorBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.red)),
                                    ),
                                    inputFormatters: [tagMask],
                                  ),
                                ),
                                bottomWidget: Container(
                                  padding: EdgeInsets.all(offsetBase),
                                  child: Row(
                                    children: [
                                      Spacer(),
                                      InkWell(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: OutLineLabel(
                                            title: 'Cancel',
                                            titleColor: Colors.red,
                                          )),
                                      SizedBox(
                                        width: offsetBase,
                                      ),
                                      InkWell(
                                          onTap: () {
                                            String tag = _tagController.text;
                                            if (tag.length < 3) {
                                              DialogService(context)
                                                  .showSnackbar(
                                                      'Tag style is wrong',
                                                      _scaffoldKey,
                                                      type: SnackBarType.ERROR);
                                              return;
                                            }
                                            if (tags.contains(tag)) {
                                              DialogService(context).showSnackbar(
                                                  'This tag was already saved.',
                                                  _scaffoldKey,
                                                  type: SnackBarType.ERROR);
                                              return;
                                            }
                                            setState(() {
                                              tags.add(tag);
                                              _tagController.text = '';
                                            });
                                            Navigator.of(context).pop();
                                          },
                                          child: OutLineLabel(
                                            title: 'Add',
                                            titleColor: Colors.green,
                                          )),
                                    ],
                                  ),
                                ));
                          },
                          child: OutLineLabel(title: '+ Add')),
                    ],
                  ),
                ),
                SizedBox(
                  height: offsetSm,
                ),
                Wrap(
                  children: [
                    for (var tag in tags)
                      tagWidget(tag, isDelete: true, delete: () {
                        setState(() {
                          tags.remove(tag);
                        });
                      }),
                  ],
                ),
                SizedBox(
                  height: offsetLg,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: offsetBase),
                  child: Text(
                    'Add Feeds',
                    style: semiBold.copyWith(fontSize: fontMd),
                  ),
                ),
                SizedBox(
                  height: offsetBase,
                ),
                Container(
                  width: MediaQuery.of(context).size.width - offsetBase * 2,
                  height: MediaQuery.of(context).size.width - offsetBase * 2,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: offsetSm,
                    mainAxisSpacing: offsetSm,
                    children: List<Widget>.generate(9, (index) {
                      return (index == models.length && models.length < 9)
                          ? InkWell(
                              onTap: () {
                                showTypeDialog();
                              },
                              child: addMedalWidget())
                          : (index < models.length)
                              ? InkWell(
                                onTap: () {
                                  NavigatorService(context).pushToWidget(screen: PostFeedScreen(
                                    data: models[index].file, type: models[index].type,));
                                },
                                child: models[index].mediaWidget(
                                    models[index].type == 'IMAGE' || models[index].type == 'VIDEO'
                                        ? previewMedia(models[index])
                                        : Container(), remove: () {
                                    setState(() {
                                      models.removeAt(index);
                                    });
                                  }),
                              )
                              : Container();
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget previewMedia(item) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Center(
            child: Image.memory(base64.decode(item.thumbnail),
              fit: BoxFit.cover,
            ),
          ),
          if (item.type == 'VIDEO') Center(
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.all(Radius.circular(36 / 2)),
              ),
              child: Icon(Icons.play_arrow, color: Colors.white, size: 36 / 2,),
            ),
          ),
        ],
      ),
    );
  }

  Widget previewVideo() {
    return Container(
      alignment: Alignment.center,
      height: (MediaQuery.of(context).size.width - offsetBase * 2) * 0.56,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.all(Radius.circular(offsetBase)),
      ),
      child: AspectRatio(
        aspectRatio: _videoController.value.aspectRatio,
        child: VideoPlayer(_videoController),
      ),
    );
  }

  void showTypeDialog() {
    DialogService(context).showTypeDialog(
      chooseImage: () {
        Navigator.of(context).pop();
        showPickerDialog(isVideo: false);
      },
      chooseVideo: () {
        Navigator.of(context).pop();
        showPickerDialog(isVideo: true);
      },
      chooseDocument: () {
        Navigator.of(context).pop();
        DialogService(context).showSnackbar(notSupport, _scaffoldKey, type: SnackBarType.ERROR);
      },
      chooseLocation: () {
        Navigator.of(context).pop();
        DialogService(context).showSnackbar(notSupport, _scaffoldKey, type: SnackBarType.ERROR);
      },
      chooseLink: () {
        Navigator.of(context).pop();
        DialogService(context).showSnackbar(notSupport, _scaffoldKey, type: SnackBarType.ERROR);
      },
    );
  }

  void showPickerDialog({bool isVideo = false}) {
    var pickers = [
      {
        'icon': Icons.image,
        'title': 'From Gallery',
        'source': ImageSource.gallery,
        'color': primaryColor
      },
      {
        'icon': Icons.videocam,
        'title': 'From Camera',
        'source': ImageSource.camera,
        'color': blueColor
      },
    ];
    DialogService(context).showCustomModalBottomSheet(
      titleWidget: Container(
        padding: EdgeInsets.all(offsetBase),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: boldText.copyWith(fontSize: fontBase, color: Colors.red),
              ),
            ),
            Text(
              'Choose Media',
              style: boldText.copyWith(fontSize: fontLg),
            ),
            Text(
              'Cancel',
              style: boldText.copyWith(fontSize: fontBase, color: Colors.white),
            ),
          ],
        ),
      ),
      bodyWidget: Container(
        padding: EdgeInsets.all(offsetBase),
        child: Column(
          children: [
            Text(
              'Please choose the image picker source.',
              style: mediumText.copyWith(fontSize: fontMd),
            ),
            SizedBox(
              height: offsetMd,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: offsetLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var data in pickers)
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        if (isVideo) {
                          _vidPicker(data['source']);
                        } else {
                          _imgPicker(data['source']);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: offsetBase, vertical: offsetBase),
                        decoration: BoxDecoration(
                          gradient: getGradientColor(color: data['color']),
                          borderRadius:
                              BorderRadius.all(Radius.circular(offsetBase)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              data['icon'],
                              size: 36,
                              color: Colors.white,
                            ),
                            SizedBox(
                              height: offsetSm,
                            ),
                            Text(
                              data['title'],
                              style: semiBold.copyWith(
                                  fontSize: fontBase, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
