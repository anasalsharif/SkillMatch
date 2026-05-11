import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final String baseUrl = dotenv.env['BASE_URL']!;

class AdminStatisticsPage extends StatefulWidget {
  final String token;
  const AdminStatisticsPage({super.key, required this.token});

  @override
  _AdminStatisticsPageState createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  Map<String, dynamic>? stats;
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final res = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        final decodedStats = jsonDecode(res.body);
        setState(() {
          stats = decodedStats;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Unable to load statistics right now.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to connect to the admin service.';
        isLoading = false;
      });
    }
  }

  Future<List<dynamic>> fetchUsers({
    bool activeOnly = false,
    String? type,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/admin/users',
    ).replace(queryParameters: {if (type != null) 'type': type});

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List;
      return activeOnly
          ? users.where((u) => u['online'] == true).toList()
          : users;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<List<dynamic>> fetchJobs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/jobs'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception('Failed to load jobs');
    }
  }

  void navigateToDetail(String title, List<String> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(title: Text(title)),
              body: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) => ListTile(title: Text(items[index])),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(errorMessage!),
                    ElevatedButton(
                      onPressed: fetchStats,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatTile("Total Users", stats?['users'], () async {
                    try {
                      String type = "user";
                      final users = await fetchUsers(type: type);
                      final names =
                          users
                              .map((u) => u['name'] ?? 'No name')
                              .cast<String>()
                              .toList();
                      navigateToDetail("All Users", names);
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to load users.')),
                      );
                    }
                  }),

                  _buildStatTile("Active Now", stats?['activeToday'], () async {
                    try {
                      final users = await fetchUsers(activeOnly: true);
                      final names =
                          users
                              .map((u) => u['name'] ?? 'No name')
                              .cast<String>()
                              .toList();
                      navigateToDetail("Active Users", names);
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to load active users.'),
                        ),
                      );
                    }
                  }),

                  _buildStatTile("Total Jobs", stats?['jobs'], () async {
                    try {
                      final jobs = await fetchJobs();
                      final titles =
                          jobs
                              .map((j) => j['title'] ?? 'No title')
                              .cast<String>()
                              .toList();
                      navigateToDetail("Job Titles", titles);
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to load jobs.')),
                      );
                    }
                  }),
                  _buildStatTile(
                    "Total Organizations",
                    stats?['org'],
                    () async {
                      try {
                        String type = "org";
                        final users = await fetchUsers(type: type);
                        final names =
                            users
                                .map((u) => u['name'] ?? 'No name')
                                .cast<String>()
                                .toList();
                        navigateToDetail("All Users", names);
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to load organizations.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
    );
  }

  Widget _buildStatTile(String title, dynamic value, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.analytics),
        title: Text(title),
        trailing: Text(
          value?.toString() ?? 'N/A',
          style: const TextStyle(fontSize: 18),
        ),
        onTap: onTap,
      ),
    );
  }
}
