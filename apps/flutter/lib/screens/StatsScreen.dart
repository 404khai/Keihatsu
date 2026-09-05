import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedFilter = 'Last Week';
  final List<String> _filters = ['Last Week', 'Last Month', 'Last Year', 'All Time'];

  // Mock data for the chart
  final List<double> _weeklyData = [2.5, 4.0, 3.2, 5.5, 4.8, 6.0, 3.5];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color cardColor = isDarkMode ? Colors.white10 : Colors.white.withOpacity(0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Statistics',
          style: GoogleFonts.hennyPenny(
            textStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                icon: Icon(PhosphorIcons.caretDown(), color: textColor, size: 16),
                dropdownColor: bgColor,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                  }
                },
                items: _filters.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(child: _buildSummaryCard("Reading Time", "24.5h", PhosphorIcons.clock(), brandColor, cardColor, textColor)),
                const SizedBox(width: 15),
                Expanded(child: _buildSummaryCard("Titles Read", "12", PhosphorIcons.bookOpen(), brandColor, cardColor, textColor)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildSummaryCard("Comments", "48", PhosphorIcons.chatCircleText(), brandColor, cardColor, textColor)),
                const SizedBox(width: 15),
                Expanded(child: _buildSummaryCard("Chapters", "342", PhosphorIcons.listBullets(), brandColor, cardColor, textColor)),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Bar Chart Section
            Text(
              "Daily Activity",
              style: GoogleFonts.hennyPenny(
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(_weeklyData.length, (index) {
                        return _buildBar(_weeklyData[index], _days[index], brandColor, textColor);
                      }),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Recently Finished
            Text(
              "Top Genres",
              style: GoogleFonts.hennyPenny(
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            const SizedBox(height: 15),
            _buildGenreStats("Action", 0.8, brandColor, cardColor, textColor),
            _buildGenreStats("Fantasy", 0.6, brandColor, cardColor, textColor),
            _buildGenreStats("Romance", 0.4, brandColor, cardColor, textColor),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, PhosphorIconData icon, Color brandColor, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: brandColor, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.denkOne(
              textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          Text(
            title,
            style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double value, String label, Color brandColor, Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: value * 25, // Scale the height
          decoration: BoxDecoration(
            color: brandColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGenreStats(String genre, double percent, Color brandColor, Color cardColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(genre, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              Text("${(percent * 100).toInt()}%", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: cardColor,
              color: brandColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
