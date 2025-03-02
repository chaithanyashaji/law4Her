import 'package:flutter/material.dart';
import 'package:law4her/admin/verifylawyer.dart';
import 'package:law4her/admin/forumreport.dart';
import 'package:law4her/admin/lawyerreport.dart';
import 'package:law4her/admin/lawyerlist.dart';
import 'package:law4her/admin/lawyerpayments.dart'; // Import the new page

class AdminHomePage extends StatelessWidget {
  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 5,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDashboardCard(
              icon: Icons.verified_user,
              label: 'Verify Lawyer',
              onTap: () => _navigateToVerifyLawyer(context),
            ),
            SizedBox(height: 20),
            _buildDashboardCard(
              icon: Icons.forum,
              label: 'Forum Reports',
              onTap: () => _navigateToForumReports(context),
            ),
            SizedBox(height: 20),
            _buildDashboardCard(
              icon: Icons.report,
              label: 'Lawyer Reports',
              onTap: () => _navigateToLawyerReports(context),
            ),
            SizedBox(height: 20),
            _buildDashboardCard(
              icon: Icons.list,
              label: 'Lawyer List',
              onTap: () => _navigateToLawyerList(context),
            ),
            SizedBox(height: 20),
            _buildDashboardCard(
              icon: Icons.payment,
              label: 'Lawyer Payments',
              onTap: () => _navigateToManageLawyerPayments(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 25,
              child: Icon(
                icon,
                color: primaryColor,
                size: 30,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: primaryColor),
          ],
        ),
      ),
    );
  }

  void _navigateToVerifyLawyer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VerifyLawyer()),
    );
  }

  void _navigateToForumReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForumReportsPage()),
    );
  }

  void _navigateToLawyerReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LawyerReportsPage()),
    );
  }

  void _navigateToLawyerList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LawyerListPage()),
    );
  }

  void _navigateToManageLawyerPayments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManageLawyerPayments()),
    );
  }
}
