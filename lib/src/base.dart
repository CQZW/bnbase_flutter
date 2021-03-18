import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';

///视图控制器,定义基本的衔接问题.
abstract class ViewCtr {
  BuildContext? _context;

  ///获取context...
  BuildContext? get mContext => _context;

  BaseState? _state;

  ///获取媒体数据
  MediaQueryData get mMediaQueryData => MediaQuery.of(mContext!);

  ///显示调试banner
  bool get mShowDebugBanner => false;

  ///衔接state的 build 方法,将控件布局引入到控制器
  Widget vcBuildWidget(BuildContext context, BaseState state) {
    _context = context;
    _state = state;
    return realBuildWidget(context);
  }

  ///控制器的真正build方法
  Widget realBuildWidget(BuildContext context);

  ///导出控制器真正的布局数据
  Widget getView({Key? key});

  ///控制器更新数据,就是setstate
  void updateUI() => _state?.setState(() {});

  @mustCallSuper
  void onInitVC() {
    vclog("onInitVC");
  }

  ///调试重新热加载,reassemble被执行
  @mustCallSuper
  void onDebugReLoad() {
    vclog("onDebugReLoad...");
  }

  ///是否完成了至少一次build
  bool mIsDidBuildOnce = false;

  ///onDidBuild 之前被调用
  @mustCallSuper
  void onPreBuild() {
    vclog("onPreBuild");
  }

  ///根部组件变化之后会被执行,比如,第一次,子组件变化不会执行
  @mustCallSuper
  void onDidBuild() {
    vclog("onDidBuild");
    mIsDidBuildOnce = true;
  }

  ///被移除了显示,比如需要停止些动画什么的,deactivate被执行
  @mustCallSuper
  void onDidRemoved() {
    vclog("onDidRemoved");
  }

  ///state的dispose被执行,被释放的时候
  @mustCallSuper
  void onDispose() {
    vclog("onDispose");

    ///返回之后,直接将 _state 置空,防止继续更新
    _state = null;
  }

  void onAppLifecycleState(AppLifecycleState appState) {}

  ///是否自动保留,否则页面隐藏不显示的时候被移除了tree..,主要是tabbar的子页面
  bool wantKeepAlive = false;

  ///日志输出
  vclog(String msg) {
    log(msg);
  }
}

///基础控制器,添加常用的方法
abstract class BaseVC extends ViewCtr {
  static String mAppname = "APP_NAME";

  final Logger _logger = Logger(
      printer: PrettyPrinter(
    methodCount: 1,
    printTime: true,
  ));

  @override
  vclog(String msg) => _logger.d(msg);

  //获取控制器对应的视图
  @override
  Widget getView({Key? key}) => BaseView(key: key, vc: this);

  ///创建顶部导航栏
  PreferredSizeWidget? makeTopBar(BuildContext context) => null;

  ///创建底部tab bar..
  Widget? makeBottomBar(BuildContext context) => null;

  ///页面的背景颜色,透明,可以制作半透明的控制器
  Color? mBackGroudColor;

  bool get mIsNavVC => _mNavCtr == this;

  ///创建主要的控件部分,导航栏,tabbar,返回按钮,右侧按钮,标题等,底部tabbar由外部创建传入即可
  Widget realBuildWidget(BuildContext context) {
    Widget t = Scaffold(
      backgroundColor: mBackGroudColor,
      resizeToAvoidBottomInset: false,
      appBar: makeTopBar(context),
      body: wapperForExt(makePageBody(context), context),
      bottomNavigationBar: makeBottomBar(context),
    );
    var l = [t];

    t = Stack(
      children: l,
      fit: StackFit.expand,
      alignment: Alignment.center,
    );
    return t;

    /// 如果返回的是  MaterialApp 那么HUD可以全屏,否则HUD无法遮住导航栏,
    ///这里如果是完全没有导航栏的项目,返回 Scaffold ,如果有导航栏又需要全屏HUD就需要MaterialApp
    ///如果有了 MaterialApp 导航相关估计也有问题
  }

  ///监听导航变化
  List<NavigatorObserver> getNavObservers() => [];

  ///当获取到区域信息之后的回调
  Locale? onGetLocalInfo(Locale? locale, Iterable<Locale>? supportedLocales) {
    //记录当前系统的语言,和地区设置
    if (locale == null) return locale;
    mSysLang = locale.languageCode;
    if (locale.countryCode != null) mSysCountry = locale.countryCode!;
    vclog("get app local info:$locale");
    return locale;
  }

  ///支持哪些地域
  List<Locale> getSupportedLocals() => [Locale('zh'), Locale('en')];

  ///当前系统的语言,默认英语
  static String mSysLang = 'en';

  ///当前系统的地区,国家
  static String mSysCountry = 'US';

  ///获取主题数据
  ThemeData getThemeData(BuildContext context) {
    ///主题这玩意感觉太复杂了,flutter有自己的逻辑,如果设计不是这种思路,就太麻烦了
    ///比如按钮,看 button_theme.dart 源码,textcolor设置,不是简单的设置,是根据各个情况来自己设置的,
    return ThemeData(
      ///主题颜色,比如 导航栏背景 通常是最能表明一个App主题的,
      ///FloatingActionButton背景色也是这里
      primarySwatch: Colors.blue,
      //buttonColor: Colors.green,//RaisedButton的背景色,下面也可以设置
      //buttonTheme: ButtonTheme.of(context).copyWith(buttonColor: Colors.white, textTheme: ButtonTextTheme.primary),

      //textTheme: TextTheme(bodyText2: TextStyle(color: Colors.white)), //普通的text的前景色
      scaffoldBackgroundColor: Colors.white,

      ///APP的空白地方背景色
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  ///正常创建页面业务控件的地方,子类继承并且修改这个,
  ///就是之前的build方法里面创建body的部分
  Widget makePageBody(BuildContext context);

  ///是否需要键盘处理,比如有输入框,滚动视图,输入状态点击空白消失
  bool mEnableKeyBoardHelper = false;

  Widget wapperForKeyBoard(Widget body, BuildContext context) {
    return GestureDetector(
      child: SingleChildScrollView(child: body),
      onTap: () => onTapedWhenKeyBoardShow(),
    );
  }

  ///用于控制输入焦点.处理键盘
  FocusNode mFocusNode = FocusNode();
  void onTapedWhenKeyBoardShow() {
    mFocusNode.unfocus();
  }

  ///方便扩展处理,
  Widget wapperForExt(Widget body, BuildContext context) {
    if (mEnableKeyBoardHelper) return wapperForKeyBoard(body, context);
    return body;
  }

  ///页面名字,用于统计
  late String mPageName;

  ///用于路由的页面KEY
  String get mPageKey => mPageName;

  ///左边返回按钮被点击之后
  void onLeftBtClicked() {}

  ///页面的返回值
  dynamic mRetVal;

  //列表相关
  List mDataArr = [];
  //当前页码
  int mPage = 0;

  BaseNavVC? _mNavCtr;

  ///PUSH到指定VC,并且有返回异步返回值
  Future<dynamic> pushToVC(BaseVC to) {
    if (_mNavCtr == null) {
      log("没有导航控制器");
      return Future.value(null);
    }
    to._mNavCtr = _mNavCtr;
    return _mNavCtr!.pushToVC(to);
  }

  ///返回上一级,true表示成功,false表示无法返回,v默认是mRetVal
  bool popBack([dynamic? v]) {
    if (v != null) mRetVal = v;
    if (_mNavCtr == null) {
      log("没有导航控制器");
      return false;
    }
    return _mNavCtr!.popBack(mRetVal);
  }

  ///PUSH到指定VC,并且有返回异步返回值,淡入动画,
  Future<dynamic> pushToVCFade(BaseVC to) {
    if (_mNavCtr == null) {
      log("没有导航控制器");
      return Future.value(null);
    }
    to._mNavCtr = _mNavCtr;
    return _mNavCtr!.pushToVCFade(to);
  }

  ///半透明VC,动画从下到上
  Future<dynamic> pushToTransparentVCUpTo(BaseVC to) {
    if (_mNavCtr == null) {
      log("没有导航控制器");
      return Future.value(null);
    }
    to._mNavCtr = _mNavCtr;
    return _mNavCtr!.pushToTransparentVCUpTo(to);
  }
}

///基础的导航控制器
///目前其实我还是没太懂2.0的导航......
class BaseNavVC extends BaseVC {
  ///这个导航控制器的根视图
  final BaseVC mRootVC;
  late final BaseRouterDelegate mRouterDelegate;
  BaseNavVC(this.mRootVC) {
    this.mRootVC._mNavCtr = this;
    mRouterDelegate = BaseRouterDelegate(this);
    _mPages = [RouterPage.createRouterPageFromVC(mRootVC)];
  }

  late List<RouterPage> _mPages;

  @override
  Widget realBuildWidget(BuildContext context) {
    return MaterialApp.router(
      title: BaseVC.mAppname,
      theme: getThemeData(context),
      debugShowCheckedModeBanner: mShowDebugBanner,

      ///这玩意没搞懂~~,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        //奇葩问题,
        //https://blog.csdn.net/julystroy/article/details/90231588
        const FallbackCupertinoLocalisationsDelegate(),
      ],
      localeResolutionCallback: onGetLocalInfo,
      supportedLocales: getSupportedLocals(),
      //locale: ,先不考虑那么复杂的情况,本地这个就先不管了,遇到书写顺序有问题的再说
      routerDelegate: mRouterDelegate,
      routeInformationParser: BaseRouteInformationParser(),
    );
  }

  /*路由代理 截获*/
  Widget rbuild(BuildContext context) {
    return Navigator(
      key: mRouterDelegate.navigatorKey,
      pages: _mPages,
      onPopPage: _onPopPage,
    );
  }

  ///这里截获的是导航栏上面的返回按钮
  bool _onPopPage(Route<dynamic> route, dynamic result) {
    // if (_mPages.length <= 1) return false;
    // _mPages.remove(route.settings);
    // mRouterDelegate.notifyListeners();
    route.didPop(result);
    return popBack(result);
  }

  Future<bool> rpopRoute() {
    return Future.value(popBack(null));
  }

  /*路由代理 截获*/
  ///PUSH到控制器
  Future<dynamic> pushToVC(BaseVC to) {
    return pushToPage(RouterPage.createRouterPageFromVC(to));
  }

  ///PUSH到路由页面
  Future<dynamic> pushToPage(RouterPage page) {
    _mPages.add(page);
    _mPages = _mPages.toList();
    mRouterDelegate.notifyListeners();
    return page.getPopValue;
  }

  ///退回上一级,返回true表示已经退回,否则无法退回
  bool popBack([dynamic? v]) {
    if (_mPages.length <= 1) return false;
    RouterPage p = _mPages.removeLast();
    _mPages = _mPages.toList();
    mRouterDelegate.notifyListeners();
    p.doPop(v);
    return true;
  }

  ///PUSH到指定VC,并且有返回异步返回值,淡入动画,
  Future<dynamic> pushToVCFade(BaseVC to) {
    return pushToPage(RouterPage.createRouterPageFromVCFade(to));
  }

  ///半透明VC,动画从下到上
  Future<dynamic> pushToTransparentVCUpTo(BaseVC to) {
    return pushToPage(RouterPage.createRouterPageFromVCTransUpTo(to));
  }

  @override
  Widget makePageBody(BuildContext context) {
    // TODO: implement makePageBody
    throw UnimplementedError();
  }

  Future<void> rsetNewRoutePath(String configuration) {
    // TODO: implement setNewRoutePath
    throw UnimplementedError();
  }

  Future<void> rsetInitialRoutePath(String configuration) {
    return SynchronousFuture<void>(null);
  }
}

///路由代理
class BaseRouterDelegate extends RouterDelegate<String>
    with PopNavigatorRouterDelegateMixin<String>, ChangeNotifier {
  final BaseNavVC vc;

  BaseRouterDelegate(this.vc);

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => vc.rbuild(context);

  @override
  Future<bool> popRoute() => vc.rpopRoute();

  @override
  Future<void> setInitialRoutePath(String configuration) =>
      vc.rsetInitialRoutePath(configuration);

  @override
  Future<void> setNewRoutePath(String configuration) =>
      vc.rsetNewRoutePath(configuration);
}

///路由数据解析
class BaseRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(RouteInformation routeInformation) {
    return SynchronousFuture(routeInformation.location ?? "/");
  }

  @override
  RouteInformation restoreRouteInformation(String configuration) {
    return RouteInformation(location: configuration);
  }
}

typedef RouterPageCreateFunc = Route Function(
    BuildContext context, BaseVC vc, RouterPage page);

///页面对象
class RouterPage extends Page {
  final RouterPageCreateFunc routerCreator;
  final BaseVC vc;
  final Completer _comp = Completer();
  RouterPage(LocalKey key, this.vc, this.routerCreator) : super(key: key);

  @factory
  static RouterPage createRouterPageFromVC(BaseVC vc) {
    return RouterPage(
        ValueKey(vc.mPageKey),
        vc,
        (context, vcc, page) => MaterialPageRoute(
              settings: page,
              maintainState: true,
              builder: (context) => vcc.getView(),
            ));
  }

  @factory
  static RouterPage createRouterPageFromVCFade(BaseVC vc) {
    return RouterPage(
        ValueKey(vc.mPageKey),
        vc,
        (context, vcc, page) => PageRouteBuilder(
              settings: page,
              maintainState: true,
              transitionDuration: Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) {
                return new FadeTransition(
                  //使用渐隐渐入过渡,
                  opacity: animation,
                  child: vcc.getView(), //路由B
                );
              },
            ));
  }

  @factory
  static RouterPage createRouterPageFromVCTransUpTo(BaseVC vc) {
    return RouterPage(
        ValueKey(vc.mPageKey),
        vc,
        (context, vcc, page) => CustomTransitionRoute((context) => vc.getView(),
                transitBuilder:
                    (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                        begin: Offset(0.0, 1.0), end: Offset(0.0, 0.0))
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.fastOutSlowIn)),
                child: child,
              );
            }, settings: page));
  }

  ///在PUSH的时候等待 返回值
  Future<dynamic> get getPopValue => _comp.future;

  ///真正准备返回了,设置返回值回去了
  void doPop(dynamic? v) => _comp.complete(v);

  @override
  Route createRoute(BuildContext context) =>
      this.routerCreator(context, vc, this);
}

class BaseElement extends StatefulElement {
  BaseElement(StatefulWidget widget) : super(widget);

  @override
  void performRebuild() {
    Element? _old;
    visitChildren((element) {
      _old = element;
    });

    super.performRebuild();
    Element? _new;
    visitChildren((element) {
      _new = element;
    });

    if (_old != _new) {
      ///延迟35毫秒,30帧率,基本上可以保证已经渲染完了,可以直接在onDidBuild里面做些操作了
      Future.delayed(Duration(milliseconds: 35), () {
        (widget as BaseView).vc.onPreBuild();
        (widget as BaseView).vc.onDidBuild();
      });
    }
  }
}

///视图中间件...串联控制器的地方将控制器和state链接起来
// ignore: must_be_immutable
class BaseView extends StatefulWidget {
  final ViewCtr vc;
  BaseView({Key? key, required this.vc}) : super(key: key);

  @override
  State<BaseView> createState() => BaseState();

  @override
  StatefulElement createElement() => BaseElement(this);
}

///状态中间件....
class BaseState extends State<BaseView>
    with
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin,
        WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => widget.vc.wantKeepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.vc.vcBuildWidget(context, this);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    widget.vc.onInitVC();
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.vc.onDebugReLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
    widget.vc.onDispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.vc.onDidRemoved();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    widget.vc.onAppLifecycleState(state);
  }
}

///自定义的过度路由,主要是创建透明的路由页面
class CustomTransitionRoute extends PageRoute {
  CustomTransitionRoute(this.builder,
      {this.transitBuilder, RouteSettings? settings})
      : super(settings: settings);
  final WidgetBuilder builder;
  final RouteTransitionsBuilder? transitBuilder;

  @override
  Color? get barrierColor => null;

  @override
  bool get opaque => false;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return this.builder(context);
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (this.transitBuilder != null)
      return this.transitBuilder!(
          context, animation, secondaryAnimation, child);
    return FadeTransition(opacity: animation, child: child);
  }
}

//https://blog.csdn.net/julystroy/article/details/90231588
class FallbackCupertinoLocalisationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(FallbackCupertinoLocalisationsDelegate old) => false;
}
