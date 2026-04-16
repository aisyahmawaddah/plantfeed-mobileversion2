import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/group_sharing_model.dart';
import 'package:plant_feed/model/plantlink_chart_model.dart';
import 'package:plant_feed/screens/add_new_timeline_form_popup.dart';
import 'package:plant_feed/screens/chart_selection_screen.dart';
import 'package:plant_feed/screens/plantlink_chart_viewer_screen.dart';
import 'package:provider/provider.dart';

class GroupTimelineScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  final String groupPicture;
  const GroupTimelineScreen({Key? key, required this.groupId, required this.groupName, required this.groupPicture}) : super(key: key);

  @override
  State<GroupTimelineScreen> createState() => _GroupTimelineScreenState();
}

class _GroupTimelineScreenState extends State<GroupTimelineScreen> {
  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.groupPicture.isNotEmpty
                  ? NetworkImage("${apiService.url}/media/${widget.groupPicture}")
                  : const AssetImage('assets/images/placeholder_image.png') as ImageProvider,
              backgroundColor: Colors.white24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.groupName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Action Buttons ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AddNewTimelineScreenPopup(groupId: widget.groupId),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('New Post', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChartSelectionScreen(
                            groupId: widget.groupId,
                            groupName: widget.groupName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics, size: 16),
                    label: const Text('Share Chart', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Timeline List ───────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.green,
              child: FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  apiService.getGroupTimelines(widget.groupId),
                  apiService.getGroupCharts(widget.groupId),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.green));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }

                  final posts = snapshot.data![0] as List<GroupSharingModel>;
                  final charts = snapshot.data![1] as List<PlantLinkChartSharingModel>;

                  if (posts.isEmpty && charts.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Icon(Icons.dynamic_feed, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'No posts yet.\nBe the first to share!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    children: [
                      ...posts.map((post) => _buildPostCard(post, apiService)),
                      if (charts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Row(
                            children: [
                              const Icon(Icons.bar_chart, color: Colors.green, size: 20),
                              const SizedBox(width: 6),
                              const Text(
                                'PlantLink Charts',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${charts.length}',
                                  style: const TextStyle(color: Colors.green, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...charts.map((chart) => _buildChartCard(chart)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(GroupSharingModel post, ApiService apiService) {
    return GestureDetector(
      onTap: () {
        log(post.id.toString());
        Navigator.pushNamed(context, '/groupTimelineDetails', arguments: [
          post.creatorName,
          post.creatorUsername,
          post.creatorPhoto,
          post.createdAt,
          post.groupTitle,
          post.groupMessage,
          post.groupPhoto,
          post.id,
        ]);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Creator Row ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post.creatorPhoto.isNotEmpty
                        ? NetworkImage("${apiService.url}${post.creatorPhoto}")
                        : const AssetImage('assets/images/placeholder_image.png') as ImageProvider,
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.creatorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '@${post.creatorUsername}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text(
                        post.createdAt,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Title & Message ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.groupTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.groupMessage,
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            // ── Photo ────────────────────────────────────────────
            if (post.groupPhoto.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.network(
                  "${apiService.url}${post.groupPhoto}",
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              )
            else
              // ── Bottom Bar ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('View comments', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                  ],
                ),
              ),

            if (post.groupPhoto.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('View comments', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(PlantLinkChartSharingModel chart) {
    final knownChartTypes = ['ph', 'potassium', 'nitrogen', 'phosphorous', 'humidity', 'temperature', 'rainfall', 'Channel'];
    final isPlantLinkChart = knownChartTypes.any(
          (type) => chart.chartType.toLowerCase().contains(type.toLowerCase()),
        ) ||
        chart.link.contains('/mychannel/embed/');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Green accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isPlantLinkChart ? Colors.green : Colors.grey,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPlantLinkChart ? Colors.green[50] : Colors.grey[100],
                  child: Icon(
                    isPlantLinkChart ? Icons.analytics : Icons.link,
                    color: isPlantLinkChart ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chart.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (chart.description.isNotEmpty)
                        Text(
                          chart.description,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPlantLinkChart ? Colors.green[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          chart.chartType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isPlantLinkChart ? Colors.green[700] : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantLinkChartViewerScreen(
                        embedUrl: chart.link,
                        chartTitle: chart.title,
                        description: chart.description,
                      ),
                    ),
                  );
                },
                icon: Icon(isPlantLinkChart ? Icons.bar_chart : Icons.open_in_new, size: 16),
                label: Text(isPlantLinkChart ? 'View Chart' : 'Open Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPlantLinkChart ? Colors.green : Colors.grey[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
