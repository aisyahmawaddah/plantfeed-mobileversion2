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
      List<GroupSharingModel> allPosts = await apiService.getGroupTimelines(widget.groupId);

      setState(() {
        log(widget.groupId.toString());
        Future<List<GroupSharingModel>>.value(allPosts);
      });
    }

    return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(widget.groupName),
                CircleAvatar(
                  backgroundImage: ((widget.groupPicture).isNotEmpty) ? NetworkImage("${apiService.url}/media/${widget.groupPicture}") : const AssetImage('assets/images/placeholder_image.png') as ImageProvider,
                  backgroundColor: Colors.transparent,
                ),
              ],
            )),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Button bar
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
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
                    ElevatedButton.icon(
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
                  ],
                ),
              ),
              // Tab bar
              const TabBar(
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green,
                tabs: [
                  Tab(icon: Icon(Icons.people), text: 'Posts'),
                  Tab(icon: Icon(Icons.analytics), text: 'PlantLink Charts'),
                ],
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Group posts
                    FutureBuilder<List<GroupSharingModel>>(
                      future: apiService.getGroupTimelines(widget.groupId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(snapshot.error.toString()),
                          );
                        } else if (snapshot.hasData) {
                          if (snapshot.data!.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: refreshData,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  Center(
                                    child: Text('No post found'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return RefreshIndicator(
                              onRefresh: refreshData,
                              child: ListView.builder(
                                itemCount: snapshot.data?.length,
                                itemBuilder: (context, index) {
                                  GroupSharingModel? groupSharing = snapshot.data?[index];
                                  return InkWell(
                                    onTap: () {
                                      log(snapshot.data?[index].id.toString() ?? '');
                                      Navigator.pushNamed(context, '/groupTimelineDetails', arguments: [
                                        groupSharing?.creatorName ?? '',
                                        groupSharing?.creatorUsername ?? '',
                                        groupSharing?.creatorPhoto ?? '',
                                        groupSharing?.createdAt ?? '',
                                        groupSharing?.groupTitle ?? '',
                                        groupSharing?.groupMessage ?? '',
                                        groupSharing?.groupPhoto ?? '',
                                        groupSharing?.id ?? '',
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
                                                    backgroundImage: (groupSharing?.creatorPhoto != null && (groupSharing?.creatorPhoto ?? "").isNotEmpty) ? NetworkImage("${apiService.url}${groupSharing?.creatorPhoto}") : const AssetImage('assets/images/placeholder_image.png') as ImageProvider,
                                                    backgroundColor: Colors.transparent,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: Text(
                                                      groupSharing?.creatorName ?? '',
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
                                                      "@${groupSharing?.creatorUsername ?? ''}",
                                                      style: const TextStyle(
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 50),
                                                child: Text(groupSharing?.createdAt ?? ''),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 50),
                                                child: Text(
                                                  snapshot.data?[index].groupTitle ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 50),
                                                child: Text(groupSharing?.groupMessage ?? ''),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 50),
                                                child: (groupSharing?.groupPhoto != null && groupSharing!.groupPhoto.isNotEmpty)
                                                    ? SizedBox(
                                                        height: 250,
                                                        width: 250,
                                                        child: Image.network(
                                                          "${apiService.url}${groupSharing.groupPhoto}",
                                                        ),
                                                      )
                                                    : const SizedBox(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                    // Tab 2: PlantLink charts
                    _buildChartsTab(apiService),
                  ],
                ),
              ),
            ],
          ),
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
        ));
  }

  Widget _buildChartsTab(ApiService apiService) {
    return FutureBuilder<List<PlantLinkChartSharingModel>>(
      future: apiService.getGroupCharts(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyan),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No PlantLink charts shared yet',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final chart = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.cyan,
                  child: const Icon(Icons.bar_chart, color: Colors.white),
                ),
                title: Text(chart.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(chart.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.open_in_new, color: Colors.cyan),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlantLinkChartViewerScreen(
                        embedUrl: chart.link,
                        chartTitle: chart.title,
                        description: chart.description,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
