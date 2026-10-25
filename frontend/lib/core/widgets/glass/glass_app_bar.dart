import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final double elevation;

  static final ImageFilter _blur = ImageFilter.blur(sigmaX: 16, sigmaY: 16);

  const GlassAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading && Navigator.of(context).canPop()) {
      leadingWidget = IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      );
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: _blur,
        child: Container(
          height: preferredSize.height + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x1F0A0F1C) : const Color(0x66FFFFFF),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight,
                width: 1.0,
              ),
            ),
          ),
          child: NavigationToolbar(
            leading: leadingWidget != null
                ? ConstrainedBox(
                    constraints: const BoxConstraints.tightFor(width: 56.0),
                    child: leadingWidget,
                  )
                : null,
            middle: title ??
                (titleText != null
                    ? Text(
                        titleText!,
                        style: AppTokens.headingSmall(isDark).copyWith(fontSize: 18),
                      )
                    : null),
            trailing: actions != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  )
                : null,
            centerMiddle: false,
          ),
        ),
      ),
    );
  }
}
