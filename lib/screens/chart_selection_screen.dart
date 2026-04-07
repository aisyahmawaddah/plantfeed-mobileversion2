import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/plantlink_chart_model.dart';
import 'package:provider/provider.dart';

class ChartSelectionScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const ChartSelectionScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<ChartSelectionScreen> createState() => _ChartSelectionScreenState();
}

class _ChartSelectionScreenState extends State<ChartSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    ApiService apiService = Provider.of<ApiService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Chart - ${widget.groupName}'),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            color: Colors.cyan.shade50,
            child: const Text(
              'Select a chart to share with the group:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PlantLinkChartModel>>(
              future: apiService.getUserCharts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading charts: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics_outlined, color: Colors.grey, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'No charts available',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create some charts in PlantLink first',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showSharingDialog(context, apiService, null, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Share Custom Link'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: snapshot.data!.length + 1,
                      itemBuilder: (context, index) {
                        if (index == snapshot.data!.length) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.link, color: Colors.white),
                              ),
                              title: const Text(
                                'Others (Custom Link)',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: const Text('Share a custom chart link'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showSharingDialog(context, apiService, null, true),
                            ),
                          );
                        } else {
                          PlantLinkChartModel chart = snapshot.data![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getChartTypeColor(chart.chartType),
                                child: Icon(_getChartTypeIcon(chart.chartType), color: Colors.white),
                              ),
                              title: Text(
                                chart.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${chart.chartType}'),
                                  Text(
                                    'Period: ${_formatDate(chart.startDate)} - ${_formatDate(chart.endDate)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showSharingDialog(context, apiService, chart, false),
                            ),
                          );
                        }
                      },
                    );
                  }
                } else {
                  return const Center(child: Text('No data available'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getChartTypeColor(String chartType) {
    switch (chartType.toLowerCase()) {
      case 'line': return Colors.blue;
      case 'bar': return Colors.green;
      case 'pie': return Colors.purple;
      case 'scatter': return Colors.orange;
      default: return Colors.cyan;
    }
  }

  IconData _getChartTypeIcon(String chartType) {
    switch (chartType.toLowerCase()) {
      case 'line': return Icons.show_chart;
      case 'bar': return Icons.bar_chart;
      case 'pie': return Icons.pie_chart;
      case 'scatter': return Icons.scatter_plot;
      default: return Icons.analytics;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSharingDialog(BuildContext context, ApiService apiService, PlantLinkChartModel? chart, bool isCustomLink) {
    final titleController = TextEditingController(text: chart?.name ?? '');
    final descriptionController = TextEditingController();
    final customLinkController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share ${isCustomLink ? 'Custom Link' : 'Chart'}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCustomLink && chart != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chart: ${chart.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Type: ${chart.chartType}'),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Title is required';
                  if (value.trim().length > 100) return 'Title cannot exceed 100 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Enter description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Description is required';
                  if (value.trim().length > 500) return 'Description cannot exceed 500 characters';
                  return null;
                },
              ),
              if (isCustomLink) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: customLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Chart Link *',
                    hintText: 'Enter chart URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Chart link is required';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  PlantLinkChartSharingModel chartSharing = PlantLinkChartSharingModel(
                  id: isCustomLink ? 0 : (chart?.id ?? 0),  // was: id: 0
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  link: isCustomLink ? customLinkController.text.trim() : chart!.embedLink,
                  chartType: isCustomLink ? 'custom' : chart!.chartType,
                  groupId: widget.groupId,
                  userId: 0,
                  createdAt: DateTime.now(),
                );

                  bool success = await apiService.shareChartToGroup(chartSharing);

                  if (success) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chart shared successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to share chart'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
