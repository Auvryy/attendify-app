// lib/screens/admin/admin_leave_request_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';

class AdminLeaveRequestDetailScreen extends StatefulWidget {
  final String employeeName;
  final String leaveDate;
  final String reason;
  final String requestId;
  final String status;
  final String? attachmentUrl;
  final String leaveType;

  const AdminLeaveRequestDetailScreen({
    super.key,
    required this.employeeName,
    required this.leaveDate,
    required this.reason,
    required this.requestId,
    required this.status,
    this.attachmentUrl,
    this.leaveType = 'Other',
  });

  @override
  State<AdminLeaveRequestDetailScreen> createState() => _AdminLeaveRequestDetailScreenState();
}

class _AdminLeaveRequestDetailScreenState extends State<AdminLeaveRequestDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee Name with Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.employeeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _buildStatusBadge(widget.status),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Leave Type Section
                    _buildLeaveTypeBadge(widget.leaveType),

                    const SizedBox(height: 24),

                    // Leave On Section
                    const Text(
                      'Leave On:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.leaveDate,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Reason Section
                    const Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.reason,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Attachment Section
                    const Text(
                      'Attachment:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: widget.attachmentUrl != null ? () => _showFullImage(context) : null,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.attachmentUrl != null
                              ? Image.network(
                                  widget.attachmentUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.divider,
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image_outlined,
                                              color: AppColors.textSecondary,
                                              size: 50,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Failed to load image',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: AppColors.divider,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_outlined,
                                          color: AppColors.textSecondary,
                                          size: 50,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No attachment',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (widget.attachmentUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tap image to view full size',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Action Buttons (only show if pending)
                    if (widget.status == 'pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Decline Button
                          SizedBox(
                            width: 130,
                            height: 45,
                            child: OutlinedButton(
                              onPressed: _isProcessing ? null : () => _handleDecline(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.accent,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: const Text(
                                'Decline',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Accept Button
                          SizedBox(
                            width: 130,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : () => _handleAccept(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: _isProcessing 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Accept',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = 'Approved';
        break;
      case 'denied':
      case 'declined':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = 'Denied';
        break;
      default:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildLeaveTypeBadge(String leaveType) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String displayText = leaveType;

    switch (leaveType.toLowerCase()) {
      case 'sick leave':
      case 'sick':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.local_hospital;
        displayText = 'Sick Leave';
        break;
      case 'vacation leave':
      case 'vacation':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.beach_access;
        displayText = 'Vacation Leave';
        break;
      case 'emergency leave':
      case 'emergency':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.warning_amber;
        displayText = 'Emergency Leave';
        break;
      case 'personal leave':
      case 'personal':
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        icon = Icons.person;
        displayText = 'Personal Leave';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.event_note;
        displayText = 'Other';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.accent,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Title
          const Text(
            'Leave Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessModal(BuildContext context, {
    required String title,
    required String message,
    bool isSuccess = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.cancel,
                  color: isSuccess ? AppColors.success : AppColors.error,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppColors.success : AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleDecline(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Decline Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide a reason for declining this leave request:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for declining...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                Navigator.pop(dialogContext);
                setState(() => _isProcessing = true);
                
                final success = await context.read<AdminProvider>().reviewLeaveRequest(
                  id: widget.requestId,
                  status: 'declined',
                  adminNotes: reason.isNotEmpty ? reason : null,
                );
                
                setState(() => _isProcessing = false);
                
                if (success && mounted) {
                  _showSuccessModal(
                    context,
                    title: 'Request Declined',
                    message: 'The leave request has been declined successfully.',
                    isSuccess: false,
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<AdminProvider>().errorMessage ?? 'Failed to decline request'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text(
                'Decline',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleAccept(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Accept Request'),
          content: const Text('Are you sure you want to accept this leave request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                setState(() => _isProcessing = true);
                
                final success = await context.read<AdminProvider>().reviewLeaveRequest(
                  id: widget.requestId,
                  status: 'approved',
                );
                
                setState(() => _isProcessing = false);
                
                if (success && mounted) {
                  _showSuccessModal(
                    context,
                    title: 'Request Approved',
                    message: 'The leave request has been approved successfully.',
                    isSuccess: true,
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<AdminProvider>().errorMessage ?? 'Failed to accept request'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text(
                'Accept',
                style: TextStyle(color: AppColors.success),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFullImage(BuildContext context) {
    if (widget.attachmentUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                widget.attachmentUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Failed to load image'),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
