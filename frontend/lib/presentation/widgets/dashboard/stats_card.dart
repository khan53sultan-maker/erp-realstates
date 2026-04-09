import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';

class StatsCard extends StatefulWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Container(
                  padding: EdgeInsets.all(context.cardPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                    border: Border.all(
                      color: widget.color.withOpacity(0.1),
                      width: 0.05.w,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.all(context.smallPadding),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(context.borderRadius('small')),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: context.dashboardIconSize('medium'),
                            ),
                          ),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.smallPadding,
                              vertical: context.smallPadding * 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isPositive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(context.borderRadius('small')),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isPositive
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: widget.isPositive ? Colors.green : Colors.red,
                                  size: context.dashboardIconSize('small'),
                                ),
                                SizedBox(width: context.smallPadding * 0.5),
                                Text(
                                  widget.change,
                                  style: TextStyle(
                                    fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(context),
                                    fontWeight: FontWeight.w600,
                                    color: widget.isPositive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.formFieldSpacing * 2),

                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: ResponsiveBreakpoints.getDashboardHeaderFontSize(context),
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoalGray,
                          letterSpacing: -0.5,
                        ),
                      ),

                      SizedBox(height: context.formFieldSpacing * 0.5),

                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: ResponsiveBreakpoints.getDashboardSubtitleFontSize(context),
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                          letterSpacing: 0.2,
                        ),
                      ),

                      SizedBox(height: context.formFieldSpacing),

                      Container(
                        height: context.formFieldHeight * 0.1,
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(context.borderRadius('small')),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.isPositive ? 0.7 : 0.4,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.color,
                                  widget.color.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(context.borderRadius('small')),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
