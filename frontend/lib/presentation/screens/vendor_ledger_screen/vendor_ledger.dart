import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/providers/vendor_ledger_provider.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';

import '../../../src/models/vendor_ledger/vendor_ledger_model.dart';

class VendorLedgerScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorLedgerScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<VendorLedgerScreen> createState() => _VendorLedgerScreenState();
}

class _VendorLedgerScreenState extends State<VendorLedgerScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    debugPrint('🔵 VendorLedgerScreen initialized with vendorId: ${widget.vendorId}, vendorName: ${widget.vendorName}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLedger();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLedger() async {
    debugPrint('🔵 Loading ledger for vendor: ${widget.vendorId}');
    final provider = context.read<VendorLedgerProvider>();
    await provider.loadVendorLedger(
      vendorId: widget.vendorId,
      vendorName: widget.vendorName,
    );
    debugPrint('✅ Ledger loaded successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      appBar: _buildAppBar(context),
      body: Consumer<VendorLedgerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          if (provider.hasError) {
            return _buildErrorState(provider.errorMessage ?? 'An error occurred');
          }

          if (!provider.hasLedgerEntries) {
            return _buildEmptyState();
          }

          return _buildLedgerContent(provider);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppTheme.primaryMaroon,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppTheme.pureWhite),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendor Ledger',
            style: TextStyle(
              fontSize: context.headerFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.pureWhite,
            ),
          ),
          Text(
            widget.vendorName,
            style: TextStyle(
              fontSize: context.captionFontSize,
              color: AppTheme.pureWhite.withOpacity(0.8),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.filter_list_rounded, color: AppTheme.pureWhite),
          onPressed: () => _showFilterDialog(),
        ),
        IconButton(
          icon: Icon(Icons.download_rounded, color: AppTheme.pureWhite),
          onPressed: () => _showExportDialog(),
        ),
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: AppTheme.pureWhite),
          onPressed: () => _loadLedger(),
        ),
        SizedBox(width: context.smallPadding),
      ],
    );
  }

  Widget _buildLedgerContent(VendorLedgerProvider provider) {
    debugPrint('📊 Building ledger content with ${provider.ledgerEntries.length} entries');
    return Column(
      children: [
        // Summary Card
        if (provider.summary != null) _buildSummaryCard(provider.summary!),

        // Ledger Table
        Expanded(
          child: Container(
            margin: EdgeInsets.all(context.mainPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: context.shadowBlur('light'),
                  offset: Offset(0, context.smallPadding / 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTableHeader(),
                Expanded(
                  child: _buildLedgerTable(provider.ledgerEntries),
                ),
                _buildPagination(provider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(VendorLedgerSummary summary) {
    return Container(
      margin: EdgeInsets.all(context.mainPadding),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.3),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding / 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            'Opening Balance',
            summary.formattedOpeningBalance,
            Icons.account_balance_wallet_rounded,
          ),
          _buildDivider(),
          _buildSummaryItem(
            'Total Debits',
            summary.formattedTotalDebits,
            Icons.arrow_upward_rounded,
            color: Colors.red[300],
          ),
          _buildDivider(),
          _buildSummaryItem(
            'Total Credits',
            summary.formattedTotalCredits,
            Icons.arrow_downward_rounded,
            color: Colors.green[300],
          ),
          _buildDivider(),
          _buildSummaryItem(
            'Closing Balance',
            summary.formattedClosingBalance,
            Icons.account_balance_rounded,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label,
      String value,
      IconData icon, {
        Color? color,
        bool isHighlight = false,
      }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: color ?? AppTheme.pureWhite.withOpacity(0.9),
            size: context.iconSize('large'),
          ),
          SizedBox(height: context.smallPadding / 2),
          Text(
            label,
            style: TextStyle(
              fontSize: context.captionFontSize,
              color: AppTheme.pureWhite.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.smallPadding / 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight
                  ? context.headerFontSize
                  : context.bodyFontSize,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              color: AppTheme.pureWhite,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: AppTheme.pureWhite.withOpacity(0.2),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.cardPadding,
        vertical: context.cardPadding / 1.5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.creamWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius()),
          topRight: Radius.circular(context.borderRadius()),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Date', flex: 2),
          _buildHeaderCell('Description', flex: 4),
          _buildHeaderCell('Type', flex: 2),
          _buildHeaderCell('Debit', flex: 2),
          _buildHeaderCell('Credit', flex: 2),
          _buildHeaderCell('Balance', flex: 2),
          _buildHeaderCell('Reference', flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.bodyFontSize,
          fontWeight: FontWeight.w600,
          color: AppTheme.charcoalGray,
        ),
      ),
    );
  }

  Widget _buildLedgerTable(List<VendorLedgerEntry> entries) {
    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: AppTheme.creamWhite,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildLedgerRow(entry, index);
      },
    );
  }

  Widget _buildLedgerRow(VendorLedgerEntry entry, int index) {
    final isEven = index % 2 == 0;

    return InkWell(
      onTap: () => _showEntryDetails(entry),
      hoverColor: AppTheme.primaryMaroon.withOpacity(0.05),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.cardPadding,
          vertical: context.cardPadding / 1.5,
        ),
        color: isEven ? AppTheme.pureWhite : AppTheme.creamWhite.withOpacity(0.3),
        child: Row(
          children: [
            _buildDataCell(entry.formattedDate, flex: 2),
            _buildDataCell(
              entry.description,
              flex: 4,
              maxLines: 2,
            ),
            _buildTypeCell(entry.transactionType, flex: 2),
            _buildDataCell(
              entry.formattedDebit,
              flex: 2,
              color: entry.isDebit ? Colors.red[700] : null,
              fontWeight: entry.isDebit ? FontWeight.w600 : FontWeight.normal,
            ),
            _buildDataCell(
              entry.formattedCredit,
              flex: 2,
              color: entry.isCredit ? Colors.green[700] : null,
              fontWeight: entry.isCredit ? FontWeight.w600 : FontWeight.normal,
            ),
            _buildDataCell(
              entry.formattedBalance,
              flex: 2,
              fontWeight: FontWeight.w600,
            ),
            _buildDataCell(
              entry.referenceNumber ?? '-',
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(
      String text, {
        int flex = 1,
        int maxLines = 1,
        Color? color,
        FontWeight? fontWeight,
      }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.bodyFontSize,
          color: color ?? AppTheme.charcoalGray,
          fontWeight: fontWeight,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTypeCell(String type, {int flex = 1}) {
    Color bgColor;
    Color textColor;

    switch (type.toUpperCase()) {
      case 'DEBIT':
        bgColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        break;
      case 'CREDIT':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        break;
      case 'PAYMENT':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        break;
      case 'PURCHASE':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        break;
      case 'RETURN':
        bgColor = Colors.purple[50]!;
        textColor = Colors.purple[700]!;
        break;
      default:
        bgColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
    }

    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.smallPadding,
          vertical: context.smallPadding / 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: context.captionFontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPagination(VendorLedgerProvider provider) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.creamWhite,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(context.borderRadius()),
          bottomRight: Radius.circular(context.borderRadius()),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${provider.ledgerEntries.length} of ${provider.totalCount} entries',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: Colors.grey[600],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded),
                onPressed: provider.hasPrevious
                    ? () => provider.loadPreviousPage()
                    : null,
                color: provider.hasPrevious
                    ? AppTheme.primaryMaroon
                    : Colors.grey[400],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.cardPadding,
                  vertical: context.smallPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                ),
                child: Text(
                  'Page ${provider.currentPage} of ${provider.totalPages}',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryMaroon,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded),
                onPressed: provider.hasNext ? () => provider.loadNextPage() : null,
                color: provider.hasNext
                    ? AppTheme.primaryMaroon
                    : Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    debugPrint('⏳ Showing loading state');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            'Loading ledger...',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    debugPrint('❌ Showing error state: $message');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: context.iconSize('large') * 2,
            color: Colors.red[300],
          ),
          SizedBox(height: context.mainPadding),
          Text(
            message,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.mainPadding),
          ElevatedButton.icon(
            onPressed: _loadLedger,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: AppTheme.pureWhite,
              padding: EdgeInsets.symmetric(
                horizontal: context.cardPadding * 1.5,
                vertical: context.cardPadding,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    debugPrint('📭 Showing empty state');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: context.iconSize('large') * 3,
            color: Colors.grey[300],
          ),
          SizedBox(height: context.mainPadding),
          Text(
            'No ledger entries found',
            style: TextStyle(
              fontSize: context.headerFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            'This vendor has no transactions yet',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(VendorLedgerEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
        title: Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryMaroon,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Date', entry.formattedDate),
              _buildDetailRow('Type', entry.transactionType),
              _buildDetailRow('Description', entry.description),
              if (entry.debit > 0) _buildDetailRow('Debit', entry.formattedDebit),
              if (entry.credit > 0) _buildDetailRow('Credit', entry.formattedCredit),
              _buildDetailRow('Balance', entry.formattedBalance),
              if (entry.referenceNumber != null)
                _buildDetailRow('Reference', entry.referenceNumber!),
              if (entry.paymentMethod != null)
                _buildDetailRow('Payment Method', entry.paymentMethod!),
              if (entry.notes != null) _buildDetailRow('Notes', entry.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallPadding / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                color: AppTheme.charcoalGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
        title: Text(
          'Filter Ledger',
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryMaroon,
          ),
        ),
        content: Text(
          'Filter functionality coming soon!',
          style: TextStyle(fontSize: context.bodyFontSize),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
        title: Text(
          'Export Ledger',
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryMaroon,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportLedger('pdf');
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Colors.green),
              title: Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportLedger('excel');
              },
            ),
            ListTile(
              leading: Icon(Icons.text_snippet, color: Colors.blue),
              title: Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportLedger('csv');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLedger(String format) async {
    final provider = context.read<VendorLedgerProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.pureWhite),
              strokeWidth: 2,
            ),
            SizedBox(width: context.smallPadding),
            Text('Exporting as ${format.toUpperCase()}...'),
          ],
        ),
        backgroundColor: AppTheme.primaryMaroon,
      ),
    );

    final result = await provider.exportVendorLedger(
      vendorId: widget.vendorId,
      format: format,
    );

    if (result != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Export successful!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => messenger.hideCurrentSnackBar(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
