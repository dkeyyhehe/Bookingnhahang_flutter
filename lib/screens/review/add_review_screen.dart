import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../models/restaurant.dart';
import '../../models/review.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  Restaurant? _restaurant;
  AppUser? _currentUser;
  int _selectedRating = 5;
  bool _isLoading = false;
  bool _hasReviewed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restaurant == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Restaurant) {
        setState(() {
          _restaurant = args;
        });
        // Load user and check hasReviewed in background
        _loadUserAndCheckReview();
      }
    }
  }

  Future<void> _loadUserAndCheckReview() async {
    if (_restaurant == null) return;

    // Load current user
    final appUser = await _authService.getCurrentAppUser();
    if (appUser != null && mounted) {
      setState(() {
        _currentUser = appUser;
      });

      // Check if user has already reviewed (in background, don't block UI)
      _firestoreService.hasUserReviewed(
        appUser.uid,
        _restaurant!.id,
      ).then((hasReviewed) {
        if (mounted) {
          setState(() {
            _hasReviewed = hasReviewed;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_restaurant == null || _currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final review = Review(
        id: '', // Will be set by Firestore
        restaurantId: _restaurant!.id,
        userId: _currentUser!.uid,
        userName: _currentUser!.name,
        userAvatar: _currentUser!.avatarUrl,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        timestamp: DateTime.now(),
      );

      await _firestoreService.createReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đánh giá đã được gửi thành công!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show form immediately, even if user data is still loading
    if (_restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Viết đánh giá')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viết đánh giá'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _restaurant!.imageUrl.startsWith('http')
                            ? Image.network(
                                _restaurant!.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/restaurant.jpg',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.asset(
                                _restaurant!.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.restaurant),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _restaurant!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _restaurant!.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Rating selector
              const Text(
                'Đánh giá của bạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 48,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              
              // Comment field
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Nhận xét của bạn',
                  hintText: 'Chia sẻ trải nghiệm của bạn về nhà hàng này...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập nhận xét';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasReviewed || _isLoading
                      ? null
                      : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_hasReviewed
                          ? 'Bạn đã đánh giá nhà hàng này'
                          : 'Gửi đánh giá'),
                ),
              ),
              if (_hasReviewed)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Bạn chỉ có thể đánh giá một lần cho mỗi nhà hàng.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

