import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/bloc/search_bloc/search_bloc.dart';
import '../../widget/refresh_snackbar.dart';
import '../../widget/search/search_bar.dart';
import '../../widget/search/search_page.dart';
import '../bookmark/bloc/bookmark_screen_bloc.dart';
import '../error/error_screen.dart';
import 'bloc/history_screen_bloc.dart';
import 'history_item.dart';
import 'history_placeholder.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  ScrollController _scrollController;
  final _scrollThreshold = 500;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  _loadMore() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= _scrollThreshold) {
      BlocProvider.of<HistoryScreenBloc>(context).add(GetHistoryScreenData());
    }
  }

  _refresh() {
    BlocProvider.of<HistoryScreenBloc>(context)
        .add(ResetHistoryScreenBlocToInitialState());
    BlocProvider.of<HistoryScreenBloc>(context).add(GetHistoryScreenData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      _loadMore();
    });

    return Scaffold(
        appBar: SearchBar(
          text: 'searchHistory'.tr(),
          function: () {
            showSearch(
                context: context,
                delegate: SearchWidget(
                    searchBloc: BlocProvider.of<SearchBloc>(context),
                    isFromAPI: false,
                    isBookmark: false,
                    isHistory: true));
          },
          drawerFunction: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        body: BlocConsumer<HistoryScreenBloc, HistoryScreenState>(
          listener: (context, state) {
            if (state is HistoryScreenError) {
              Scaffold.of(context).showSnackBar(refreshSnackBar(() {
                BlocProvider.of<BookmarkScreenBloc>(context)
                    .add(ResetBookmarkScreenBlocToInitialState());
                BlocProvider.of<HistoryScreenBloc>(context)
                    .add(GetHistoryScreenData());
              }));
            }
          },
          builder: (context, state) {
            if (state is HistoryScreenLoaded) {
              return RefreshIndicator(
                color: Theme.of(context).primaryColor,
                onRefresh: () async {
                  _refresh();
                },
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                      horizontal: ScreenUtil().setWidth(20)),
                  children: [
                    Text(
                      'readHistory'.tr(),
                      style:
                          TextStyle(fontFamily: "Poppins-Bold", fontSize: 16),
                    ),
                    ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: state.hasReachedMax
                            ? state.listHistoryData.length
                            : state.listHistoryData.length + 1,
                        itemBuilder: (context, index) =>
                            (index >= state.listHistoryData.length)
                                ? SizedBox()
                                : HistoryItem(
                                    historyModel: state.listHistoryData[index]))
                  ],
                ),
              );
            } else if (state is HistoryScreenError) {
              return RefreshIndicator(
                  color: Theme.of(context).primaryColor,
                  onRefresh: () async {
                    _refresh();
                  },
                  child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Container(
                          height: MediaQuery.of(context).size.height,
                          child: ErrorPage())));
            } else {
              return buildHistoryScreenPlaceholder(context);
            }
          },
        ));
  }
}
