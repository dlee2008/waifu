import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:movie/app/modules/home/controllers/home_controller.dart';
import 'package:movie/app/modules/home/views/parse_vip_manage.dart';
import 'package:movie/app/widget/helper.dart';
import 'package:movie/app/widget/window_appbar.dart';
import 'package:movie/widget/simple_html/flutter_html.dart';
import 'package:simple/x.dart';
import 'package:xi/xi.dart';

import '../controllers/play_controller.dart';

class PlayState {
  const PlayState(this.tabIndex, this.index);
  final int tabIndex;
  final int index;
}

class PlayView extends StatefulWidget {
  const PlayView({super.key});

  @override
  State<PlayView> createState() => _PlayViewState();
}

class _PlayViewState extends State<PlayView> {
  final PlayController play = Get.find<PlayController>();
  final HomeController home = Get.find<HomeController>();

  PlayState playState = const PlayState(-1, -1);

  FocusNode focusNode = FocusNode();

  ScrollController scrollController = ScrollController();

  bool get canBeShowParseVipButton {
    return home.parseVipList.isNotEmpty;
  }

  double get screenHeight {
    var ret = MediaQuery.of(context).size.height;
    return ret;
  }

  List<PlayListData> get playlist {
    return videoInfo2PlayListData(play.movieItem.videos);
  }

  get tabviewData {
    Map<int, Widget> result = {};
    playlist.asMap().forEach((key, value) {
      result[key] = Text(value.title);
    });
    return result;
  }

  bool get canRenderIosStyle {
    return playlist.length >= 4;
  }

  final double offsetSize = 12;
  final coverHeightScale = .48;

  @override
  void initState() {
    focusNode.requestFocus();
    super.initState();
  }

  handlePlay(int tabIndex, int index) async {
    var cx = playlist[tabIndex].datas[index];
    if (!await play.handleTapPlayerButtom(cx)) return;
    Future.delayed(const Duration(milliseconds: 420), () {
      playState = PlayState(tabIndex, index);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlayController>(
      builder: (play) => Scaffold(
        appBar: CupertinoEasyAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CupertinoNavigationBarBackButton(),
              if (canBeShowParseVipButton)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.collections, size: 16),
                      SizedBox(width: 6.0),
                      Text(
                        "解析源",
                        style: TextStyle(fontSize: 14.0),
                      ),
                      SizedBox(width: 2.0),
                    ],
                  ),
                  onPressed: () {
                    Get.to(() => const ParseVipManagePageView());
                  },
                ),
            ],
          ),
        ),
        body: Shortcuts(
          shortcuts: {
            // esc
            const SingleActivator(LogicalKeyboardKey.escape):
                const DismissIntent(),
            // backspace
            const SingleActivator(LogicalKeyboardKey.backspace):
                const DismissIntent(),
            // enter
            const SingleActivator(LogicalKeyboardKey.enter):
                const ActivateIntent(),
            // ctrl-p
            const SingleActivator(LogicalKeyboardKey.keyP, control: true):
                ScrollUpIntent(),
            // ctrl-n
            const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                ScrollDownIntent(),
            // // cmd-shift-[
            // const SingleActivator(LogicalKeyboardKey.braceLeft /* { */,
            //     meta: true, shift: true): TabSwitchLeftIntent(),
            // // cmd-shift-]
            // const SingleActivator(LogicalKeyboardKey.braceRight /* } */,
            //     meta: true, shift: true): TabSwitchRightIntent(),
          },
          child: Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  Get.back();
                  return null;
                },
              ),
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  // 如果只有一集的话, 敲击 `enter` 键自动播放
                  var cx = playlist[play.tabIndex].datas;
                  if (cx.length == 1) {
                    handlePlay(play.tabIndex, 0);
                  }
                  return null;
                },
              ),
              ScrollUpIntent: CallbackAction<ScrollUpIntent>(
                onInvoke: (_) {
                  scrollUp(scrollController);
                  return null;
                },
              ),
              ScrollDownIntent: CallbackAction<ScrollDownIntent>(
                onInvoke: (_) {
                  scrollDown(scrollController);
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              focusNode: focusNode,
              child: SafeArea(
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: context.isDarkMode ? Colors.white : Colors.black,
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: screenHeight * coverHeightScale,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(246, 246, 246, 1),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  play.movieItem.smallCoverImage,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) {
                                    return Image.asset(
                                      K_DEFAULT_IMAGE,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(child: SizedBox.shrink()),
                                  Container(
                                    width: double.infinity,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(
                                      color: Colors.black12,
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 24,
                                        sigmaY: 24,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          play.movieItem.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                  color: context.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWithDesc,
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              child: const Text(
                                "播放列表",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const Divider(),
                            Container(
                              width: double.infinity,
                              height: canRenderIosStyle ? 32 + 12 : null,
                              decoration: canRenderIosStyle
                                  ? BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.withOpacity(.2),
                                          width: 1,
                                        ),
                                      ),
                                    )
                                  : null,
                              padding: canRenderIosStyle
                                  ? const EdgeInsets.only(
                                      bottom: 12,
                                    )
                                  : null,
                              child: Builder(builder: (_) {
                                var isNext = playlist.length <= 1 ||
                                    tabviewData[1] == null;
                                if (isNext) return const SizedBox.shrink();
                                if (canRenderIosStyle) {
                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: playlist.length,
                                    itemBuilder: (context, index) {
                                      var isCurrentIndex =
                                          index == play.tabIndex;
                                      var current = playlist[index];
                                      var currentBorderColor = isCurrentIndex
                                          ? CupertinoTheme.of(context)
                                              .primaryColor
                                          : (context.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black)
                                              .withOpacity(.42);
                                      return GestureDetector(
                                        onTap: () {
                                          play.changeTabIndex(index);
                                        },
                                        child: AnimatedContainer(
                                          alignment: Alignment.center,
                                          height: 32,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: currentBorderColor,
                                            ),
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                            left: 9,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: Text(
                                            current.title,
                                            style: TextStyle(
                                              color: currentBorderColor,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: CupertinoSlidingSegmentedControl(
                                    backgroundColor: Colors.black26,
                                    thumbColor: context.isDarkMode
                                        ? Colors.blue
                                        : Colors.white,
                                    onValueChanged: (value) {
                                      if (value == null) return;
                                      play.changeTabIndex(value);
                                    },
                                    groupValue: play.tabIndex,
                                    children: tabviewData,
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: offsetSize),
                            Padding(
                              padding: EdgeInsets.all(offsetSize),
                              child: Builder(builder: (context) {
                                // NOTE: ↓ 若单个是否也为空
                                bool oneIsEmpty = playlist.length == 1 &&
                                    playlist[0].datas.isEmpty;
                                if (playlist.isEmpty || oneIsEmpty) {
                                  return emptyPlaylistWidget;
                                }
                                return SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * .66,
                                  child: GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisExtent: 48,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount:
                                        playlist[play.tabIndex].datas.length,
                                    itemBuilder: (context, index) {
                                      var curr =
                                          playlist[play.tabIndex].datas[index];
                                      return CupertinoButton.filled(
                                        padding: EdgeInsets.zero,
                                        child: Builder(builder: (_) {
                                          var len = playlist[play.tabIndex]
                                              .datas
                                              .length;
                                          var text =
                                              len <= 1 ? "播放" : curr.name;
                                          if (playState.tabIndex ==
                                                  play.tabIndex &&
                                              index == playState.index) {
                                            text += "(上次播放)";
                                          }
                                          return Text(text);
                                        }),
                                        onPressed: () {
                                          handlePlay(play.tabIndex, index);
                                        },
                                      );
                                    },
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final Style _textOncelineStyle = Style(
    textOverflow: TextOverflow.ellipsis,
    maxLines: 1,
    fontSize: const FontSize(
      12,
    ),
    height: 24,
  );

  final List<String> _textIncludeTags = [
    "p",
    "span",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "pre",
  ];

  Map<String, Style> get _shortDescStyleWithHTML {
    Map<String, Style> map = {};
    for (var ele in _textIncludeTags) {
      map[ele] = _textOncelineStyle;
    }
    return map;
  }

  Widget _buildWithShortDesc(String desc) {
    String humanDesc = desc.trim();
    if (humanDesc.isEmpty) return const SizedBox.shrink();
    // NOTE: 不是标签,实际上不是很严谨!!
    if (humanDesc[0] != '<') {
      return Text(
        humanDesc,
        maxLines: 1,
        style: TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 12,
          color: context.isDarkMode ? Colors.white : Colors.black,
        ),
      );
    }
    return Html(
      data: humanDesc,
      style: _shortDescStyleWithHTML,
    );
  }

  Widget get _buildWithDesc {
    var desc =
        // fuck hard-code
        play.movieItem.desc.replaceAll(r'\r\\n\t', '\n');
    if (desc.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        child: const Text('暂无简介~'),
      );
    }
    return ExpansionTile(
      initiallyExpanded: false,
      subtitle: _buildWithShortDesc(desc),
      title: Text(
        '查看简介',
        style: TextStyle(
          fontSize: 18,
          color: context.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * .33,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: Html(
                data: desc,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget get emptyPlaylistWidget {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.tornado,
            size: 42,
            color: CupertinoColors.systemBlue,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            "暂无播放链接",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
