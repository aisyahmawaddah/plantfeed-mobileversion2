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
  @override
  Widget build(BuildContext context) {
    ApiService apiService = Provider.of<ApiService>(context);

    Future<void> refreshData() async {
      setState(() {});
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(widget.groupName),
            CircleAvatar(
              backgroundImage: ((widget.groupPicture).isNotEmpty)
                  ? NetworkImage("${apiService.url}/media/${widget.groupPicture}")
                  : const AssetImage('assets/images/placeholder_image.png') as ImageProvider,
              backgroundColor: Colors.transparent,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        builder: (context) {
                          return AddNewTimelineScreenPopup(groupId: widget.groupId);
                        },
                        context: context,
                        barrierDismissible: false,
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Sharing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
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
                    icon: const Icon(Icons.analytics),
                    label: const Text('Share PlantLink Chart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshData,
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
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No posts yet'),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      ...posts.map((post) => _buildPostCard(post, apiService)),
                      if (charts.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 16, 12, 4),
                          child: Text(
                            'PlantLink Charts',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 16),
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
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Create new post'),
        backgroundColor: Colors.green,
        onPressed: () {
          showDialog(
            builder: (context) {
              return AddNewTimelineScreenPopup(groupId: widget.groupId);
            },
            context: context,
            barrierDismissible: false,
          );
        },
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostCard(GroupSharingModel groupSharing, ApiService apiService) {
    return InkWell(
      onTap: () {
        log(groupSharing.id.toString());
        Navigator.pushNamed(context, '/groupTimelineDetails', arguments: [
          groupSharing.creatorName,
          groupSharing.creatorUsername,
          groupSharing.creatorPhoto,
          groupSharing.createdAt,
          groupSharing.groupTitle,
          groupSharing.groupMessage,
          groupSharing.groupPhoto,
          groupSharing.id,
        ]);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: groupSharing.creatorPhoto.isNotEmpty
                          ? NetworkImage("${apiService.url}${groupSharing.creatorPhoto}")
                          : const AssetImage('assets/images/placeholder_image.png') as ImageProvider,
                      backgroundColor: Colors.transparent,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        groupSharing.creatorName,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        "@${groupSharing.creatorUsername}",
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Text(groupSharing.createdAt),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Text(
                    groupSharing.groupTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Text(groupSharing.groupMessage),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: groupSharing.groupPhoto.isNotEmpty
                      ? SizedBox(
                          height: 250,
                          width: 250,
                          child: Image.network("${apiService.url}${groupSharing.groupPhoto}"),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(PlantLinkChartSharingModel chart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.cyan,
                child: Icon(Icons.analytics, color: Colors.white),
              ),
              title: Text(
                chart.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (chart.description.isNotEmpty)
                    Text(
                      chart.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    chart.chartType.toUpperCase(),
                    style: const TextStyle(color: Colors.cyan, fontSize: 12),
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
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View Chart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
