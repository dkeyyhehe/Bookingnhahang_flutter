import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/restaurant.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class ManageRestaurantsScreen extends StatelessWidget {
  const ManageRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();

    return Scaffold(
      body: StreamBuilder<List<Restaurant>>(
        stream: _firestoreService.getRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final restaurants = snapshot.data ?? [];

          if (restaurants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhà hàng nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditRestaurantScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm nhà hàng'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: restaurant.imageUrl.startsWith('http')
                        ? Image.network(
                            restaurant.imageUrl,
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
                          )
                        : Image.asset(
                            restaurant.imageUrl,
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
                  title: Text(
                    restaurant.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.address),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text('${restaurant.rating}'),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditRestaurantScreen(
                                restaurant: restaurant,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(
                          context,
                          restaurant,
                          _firestoreService,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditRestaurantScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhà hàng'),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    Restaurant restaurant,
    FirestoreService firestoreService,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhà hàng'),
        content: Text('Bạn có chắc muốn xóa "${restaurant.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        final storageService = StorageService();
        
        // Delete image from Storage if it's a Firebase Storage URL
        if (restaurant.imageUrl.startsWith('http') &&
            restaurant.imageUrl.contains('firebasestorage')) {
          await storageService.deleteImage(restaurant.imageUrl);
        }

        // Delete restaurant document
        await firestoreService.deleteRestaurant(restaurant.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa nhà hàng thành công')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }
}

class AddEditRestaurantScreen extends StatefulWidget {
  final Restaurant? restaurant;

  const AddEditRestaurantScreen({super.key, this.restaurant});

  @override
  State<AddEditRestaurantScreen> createState() =>
      _AddEditRestaurantScreenState();
}

class _AddEditRestaurantScreenState extends State<AddEditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ratingController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _imageUrl;
  String? _selectedAssetImage;
  bool _isLoading = false;
  bool _isUploading = false;

  // Danh sách ảnh có sẵn trong assets
  final List<String> _assetImages = [
    'assets/images/restaurant.jpg',
    'assets/images/booking.png',
    'assets/images/nhahang1.png',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.restaurant != null) {
      _nameController.text = widget.restaurant!.name;
      _addressController.text = widget.restaurant!.address;
      _descriptionController.text = widget.restaurant!.description;
      _ratingController.text = widget.restaurant!.rating.toString();
      // Check if imageUrl is an asset path
      if (widget.restaurant!.imageUrl.startsWith('assets/')) {
        _selectedAssetImage = widget.restaurant!.imageUrl;
      } else {
        _imageUrl = widget.restaurant!.imageUrl;
      }
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrl = null; // Clear old URL when new image is selected
          _selectedAssetImage = null; // Clear asset selection
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: ${e.toString()}')),
        );
      }
    }
  }

  void _selectAssetImage(String assetPath) {
    setState(() {
      _selectedAssetImage = assetPath;
      _selectedImage = null; // Clear file selection
      _imageUrl = null; // Clear URL selection
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _imageUrl;

      // Priority: Selected file > Selected asset > Existing URL
      if (_selectedImage != null) {
        // Upload new image from file
        setState(() => _isUploading = true);
        
        // Delete old image if editing and old image is from Firebase Storage
        if (widget.restaurant != null &&
            widget.restaurant!.imageUrl.startsWith('http') &&
            widget.restaurant!.imageUrl.contains('firebasestorage')) {
          await _storageService.deleteImage(widget.restaurant!.imageUrl);
        }

        // Upload new image
        finalImageUrl = await _storageService.uploadImage(
          _selectedImage!,
          'restaurants',
        );
        
        setState(() => _isUploading = false);
      } else if (_selectedAssetImage != null) {
        // Use selected asset image
        finalImageUrl = _selectedAssetImage;
      }

      final restaurant = Restaurant(
        id: widget.restaurant?.id ?? '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: finalImageUrl ?? 'assets/images/restaurant.jpg',
        rating: double.tryParse(_ratingController.text) ?? 0.0,
      );

      if (widget.restaurant == null) {
        // Create new
        await _firestoreService.createRestaurant(restaurant);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm nhà hàng thành công')),
          );
        }
      } else {
        // Update existing
        await _firestoreService.updateRestaurant(
          widget.restaurant!.id,
          restaurant,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật nhà hàng thành công')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant == null
            ? 'Thêm nhà hàng'
            : 'Sửa nhà hàng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Preview/Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _isUploading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : _selectedAssetImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    _selectedAssetImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : _imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _imageUrl!.startsWith('http')
                                          ? Image.network(
                                              _imageUrl!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  'assets/images/restaurant.jpg',
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              _imageUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_photo_alternate,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Chọn ảnh từ thư viện',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                ),
              ),
              const SizedBox(height: 8),
              // Chọn ảnh từ Assets
              const Text(
                'Hoặc chọn ảnh có sẵn:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _assetImages.map((assetPath) {
                  final isSelected = _selectedAssetImage == assetPath;
                  return GestureDetector(
                    onTap: () => _selectAssetImage(assetPath),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.orange : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên nhà hàng *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên nhà hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(
                  labelText: 'Đánh giá (0.0 - 5.0)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final rating = double.tryParse(value);
                    if (rating == null || rating < 0 || rating > 5) {
                      return 'Đánh giá phải từ 0.0 đến 5.0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.restaurant == null
                        ? 'Thêm nhà hàng'
                        : 'Cập nhật'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


