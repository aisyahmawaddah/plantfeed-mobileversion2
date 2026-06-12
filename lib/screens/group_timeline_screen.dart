import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/chart_comment_model.dart';
import 'package:plant_feed/model/group_sharing_model.dart';
import 'package:plant_feed/model/membership_model.dart';
import 'package:plant_feed/model/plantlink_chart_model.dart';
import 'package:plant_feed/screens/add_new_timeline_form_popup.dart';
import 'package:plant_feed/screens/chart_selection_screen.dart';
import 'package:plant_feed/screens/plantlink_chart_viewer_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FeedItem {
  final String type;
  final GroupSharingModel? post;
  final PlantLinkChartSharingModel? chart;
  final DateTime date;

  _FeedItem({required this.type, this.post, this.chart, required this.date});
}

class GroupTimelineScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  final String groupPicture;

  const GroupTimelineScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.groupPicture,
  }) : super(key: key);

  @override
  State<GroupTimelineScreen> createState() => _GroupTimelineScreenState();
}

class _GroupTimelineScreenState extends State<GroupTimelineScreen> {
  Future<void> _refreshData() async => setState(() {});

  List<_FeedItem> _buildFeed(
      List<GroupSharingModel> posts, List<PlantLinkChartSharingModel> charts) {
    final feed = <_FeedItem>[];

    for (final post in posts) {
      DateTime date = DateTime(2000);
      try {
        date = DateTime.parse(post.createdAt);
      } catch (_) {}
      feed.add(_FeedItem(type: 'post', post: post, date: date));
    }

    for (final chart in charts) {
      feed.add(_FeedItem(
        type: 'chart',
        chart: chart,
        date: chart.createdAt ?? DateTime(2000),
      ));
    }

    feed.sort((a, b) => b.date.compareTo(a.date));
    return feed;
  }

  void _showMembersSheet(BuildContext context, ApiService apiService) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: const [
                Icon(Icons.people, color: Colors.white),
                SizedBox(width: 8),
                Text('Group Members',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MembershipModel>>(
              future: apiService.getMembershipList(widget.groupId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4CAF50)));
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const Center(child: Text('No members found'));
                }
                return ListView.builder(
                  itemCount: snap.data!.length,
                  itemBuilder: (context, i) {
                    final m = snap.data![i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: m.photo.isNotEmpty
                            ? NetworkImage(
                                '${apiService.url}${m.photo}')
                            : const AssetImage(
                                    'assets/images/placeholder_image.png')
                                as ImageProvider,
                      ),
                      title: Text(m.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text('@${m.username}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showChartCommentsSheet(BuildContext context, ApiService apiService,
      PlantLinkChartSharingModel chart) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Comments — ${chart.title}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 300,
                child: FutureBuilder<List<ChartCommentModel>>(
                  future: apiService.getChartComments(chart.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF4CAF50)));
                    }
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return const Center(
                          child: Text('No comments yet. Be the first!',
                              style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: snap.data!.length,
                      itemBuilder: (context, i) {
                        final c = snap.data![i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: c.commenterPhoto.isNotEmpty
                                  ? NetworkImage(
                                      '${apiService.url}${c.commenterPhoto}')
                                  : const AssetImage(
                                          'assets/images/placeholder_image.png')
                                      as ImageProvider,
                            ),
                            title: Text(c.commenterName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            subtitle: Text(c.message),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final text = commentController.text.trim();
                        if (text.isEmpty) return;
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getInt('ID') ?? 0;
                        await apiService.postChartComment(
                            chart.id, text, userId);
                        commentController.clear();
                        setSheetState(() {});
                        Navigator.pop(ctx);
                        _showChartCommentsSheet(context, apiService, chart);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  ? NetworkImage(
                      '${apiService.url}/media/${widget.groupPicture}')
                  : const AssetImage('assets/images/placeholder_image.png')
                      as ImageProvider,
              backgroundColor: Colors.white24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.groupName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Group Members',
            onPressed: () => _showMembersSheet(context, apiService),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AddNewTimelineScreenPopup(
                            groupId: widget.groupId),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('New Post',
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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
                    label: const Text('Share Chart',
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                    return const Center(
                        child:
                            CircularProgressIndicator(color: Colors.green));
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(snapshot.error.toString()));
                  }

                  final posts =
                      snapshot.data![0] as List<GroupSharingModel>;
                  final charts =
                      snapshot.data![1] as List<PlantLinkChartSharingModel>;
                  final feed = _buildFeed(posts, charts);

                  if (feed.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Icon(Icons.dynamic_feed,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'No posts yet.\nBe the first to share!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey, fontSize: 15),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: feed.length,
                    itemBuilder: (context, index) {
                      final item = feed[index];
                      if (item.type == 'post') {
                        return _buildPostCard(item.post!, apiService);
                      } else {
                        return _buildChartCard(item.chart!, apiService);
                      }
                    },
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post.creatorPhoto.isNotEmpty
                        ? NetworkImage(
                            '${apiService.url}${post.creatorPhoto}')
                        : const AssetImage(
                                'assets/images/placeholder_image.png')
                            as ImageProvider,
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.creatorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        Text('@${post.creatorUsername}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text(
                    post.createdAt,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(post.groupTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.groupMessage,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[800]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            if (post.groupPhoto.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.network(
                  '${apiService.url}${post.groupPhoto}',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.comment_outlined,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('View comments',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: Colors.grey[400]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(
      PlantLinkChartSharingModel chart, ApiService apiService) {
    final knownTypes = [
      'ph', 'potassium', 'nitrogen', 'phosphorous', 'humidity',
      'temperature', 'rainfall', 'channel'
    ];
    final isPlantLinkChart =
        knownTypes.any((t) => chart.chartType.toLowerCase().contains(t)) ||
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
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isPlantLinkChart ? Colors.green : Colors.grey,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPlantLinkChart
                      ? Colors.green[50]
                      : Colors.grey[100],
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
                      Text(chart.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      if (chart.description.isNotEmpty)
                        Text(
                          chart.description,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPlantLinkChart
                                  ? Colors.green[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chart.chartType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: isPlantLinkChart
                                    ? Colors.green[700]
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (chart.isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Live',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold)),
                            )
                          else if (chart.startDate != null &&
                              chart.endDate != null)
                            Text(
                              '${chart.startDate!.day}/${chart.startDate!.month}/${chart.startDate!.year} – ${chart.endDate!.day}/${chart.endDate!.month}/${chart.endDate!.year}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500]),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
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
                    icon: Icon(
                        isPlantLinkChart
                            ? Icons.bar_chart
                            : Icons.open_in_new,
                        size: 16),
                    label: Text(
                        isPlantLinkChart ? 'View Chart' : 'Open Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPlantLinkChart ? Colors.green : Colors.grey[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showChartCommentsSheet(context, apiService, chart),
                  icon: const Icon(Icons.comment_outlined,
                      size: 16, color: Colors.green),
                  label: const Text('Comments',
                      style: TextStyle(color: Colors.green)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}