import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/providers/product.dart';
import 'package:provider/provider.dart';

/// this screen is for edit and add new product.**/
class EditProductScreen extends StatefulWidget {
  static const String routeName = '/editProduct-screen';

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  ///we use focus node to move from on field to another and to listen on changes of focus on that field.
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageUrlFocusNode = FocusNode();
  final _imageUrlController = TextEditingController();

  ///control a field like get text
  final _formKey = GlobalKey<FormState>();

  ///get spacial key for form widget
  Product _product;
  String _productId, _title = '', _description = '', _imageUrl;
  double _price;
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void initState() {
    ///so whenever we lose the focus on the image's url field,
    /// we rebuild the UI to fitch an image witch its url is in controller.
    _imageUrlFocusNode.addListener(_updateImage);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      ///we can't call modalRoute.of from context because the widget isn't build completely yet.
      final productId = ModalRoute.of(context).settings.arguments as String;

      ///if we now edit existing product(by pass his id as argument) or add new one.
      if (productId != null) {
        _product = Provider.of<Products>(context, listen: false).getById(productId);
        _productId = productId;
        _title = _product.title;
        _description = _product.description;
        _price = _product.price;
        _imageUrlController.text = _imageUrl = _product.imageUrl;
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    ///free up the memory.
    _imageUrlFocusNode.removeListener(_updateImage);
    _imageUrlController.dispose();
    _imageUrlFocusNode.dispose();
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  ///this fun will be called if the user clicks on other component.
  void _updateImage() {
    if (!_imageUrlFocusNode.hasFocus) {
      if (_checkUrlFormat(_imageUrlController.text)) return;
      setState(() {});
    }
  }

  Future<void> _saveForm() async {
    ///this will call all validator methods in fields and make sure all value are correct
    ///we reach the form by his key
    if (!_formKey.currentState.validate()) return;

    _formKey.currentState.save();

    _product = Product(
      id: _productId == null ? DateTime.now().toString() : _productId,
      title: _title,
      description: _description,
      price: _price,
      imageUrl: _imageUrl,
      isFavorite: _productId == null ? false : _product.isFavorite,
    );

    setState(() {
      _isLoading = true;
    });

    ///update existed product or add new one
    try {
      if (_productId == null)
        await Provider.of<Products>(context, listen: false).addItem(_product);
      else
        await Provider.of<Products>(context, listen: false).updateProduct(_product);
    } catch (_) {
      await _showAlertDialog();
    }
    Navigator.of(context).pop();
  }

  Future<void> _showAlertDialog() async {
    await showDialog<Null>(
      context: context,
      builder: (ctx) => Platform.isIOS
          ? CupertinoAlertDialog(
              title: const Text('An error occur!'),
              content: const Text('An error occurred while saving the info in server!'),
              actions: <Widget>[_flatButtonDialog(ctx)],
            )
          : AlertDialog(
              title: const Text('An error occur!'),
              content: const Text('An error occurred while saving the info in server!'),
              actions: <Widget>[_flatButtonDialog(ctx)],
            ),
    );
  }

  FlatButton _flatButtonDialog(BuildContext ctx) {
    return FlatButton(
      onPressed: () {
        Navigator.of(ctx).pop();
      },
      child: const Text('Okay'),
    );
  }

  bool _checkUrlFormat(String value) {
    return ((!value.endsWith('png') &&
            !value.endsWith('jpeg') &&
            !value.endsWith(
              'jpg',
            )) ||
        (!value.startsWith('http') && !value.startsWith('https')));
  }

  // Future<bool> _checkUrlValidation(String url) async { final response = await http.head('https://jsonplaceholder.typicode.com/posts/1'); return response.statusCode == 200; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                _saveForm();
              })
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        initialValue: _title,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          icon: Icon(
                            Icons.title,
                            color: Colors.deepOrange,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        onSaved: (value) {
                          _title = value;
                        },
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_priceFocusNode);
                        },
                        validator: (value) {
                          if (value.isEmpty) return 'please enter a title';///this message will appear under the field
                          return null;
                        },
                      ),
                      TextFormField(
                        initialValue: _price.toString() != 'null' ? _price.toString() : '',
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          icon: Icon(
                            Icons.attach_money,
                            color: Colors.deepOrange,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        focusNode: _priceFocusNode,///put it in focus tree
                        onSaved: (value) {
                          _price = double.parse(value);
                        },
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_descriptionFocusNode);
                        },
                        validator: (value) {
                          if (value.isEmpty) return 'please enter price';
                          if (double.tryParse(value) == null) return 'please enter an numerical value only';
                          if (double.parse(value) < 0) return 'please enter a positive number';
                          return null;
                        },
                      ),
                      TextFormField(
                        initialValue: _description,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          icon: Icon(
                            Icons.description_outlined,
                            color: Colors.deepOrange,
                          ),
                        ),
                        maxLength: 150,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        focusNode: _descriptionFocusNode,
                        onSaved: (value) {
                          _description = value;
                        },
                        validator: (value) {
                          if (value.isEmpty) return 'please enter a description';
                          if (value.length < 10) return 'please enter a longer description';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.deepOrange,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(180),
                            ),
                            margin: const EdgeInsets.only(right: 10),
                            width: 100,
                            height: 100,
                            child: _imageUrlController.text.isEmpty
                                ? const Center(child: Text('Enter\nImage\nUrl'))
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(180),
                                    child: Image.network(
                                      _imageUrlController.text,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Image url',
                                icon: Icon(
                                  Icons.image_search,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              keyboardType: TextInputType.url,
                              controller: _imageUrlController,
                              focusNode: _imageUrlFocusNode,
                              onFieldSubmitted: (_) {
                                _saveForm();
                              },
                              onSaved: (value) {
                                _imageUrl = value;
                              },
                              validator: (value) {
                                if (value.isEmpty) return 'please enter a url';
                                if (_checkUrlFormat(value)) return 'please enter a correct url';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
