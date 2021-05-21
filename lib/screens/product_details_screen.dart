import 'package:flutter/material.dart';
import '../providers/product.dart';

class ProductDetailsScreen extends StatelessWidget {
  static const String routeName = 'product-details-screen';

  @override
  Widget build(BuildContext context) {
    Product product = ModalRoute.of(context).settings.arguments as Product;
    return Scaffold(
      // appBar: AppBar(
      //   title: MyApp.title,
      // ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                width: double.infinity,
                color: Colors.teal.withOpacity(0.1),
                  child: Text(
                product.title,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              )),
              background: Hero(
                tag: 'productImage${product.id}',
                child: Image.network(
                  product.imageUrl,
                  // width: double.infinity,
                  fit: BoxFit.fill,
                  height: 300,
                ),
              ),
            ),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
            SizedBox(height: 30),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\$${product.price}',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
                  ),
                )),
            SizedBox(height: 20),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                product.description,
                style: TextStyle(fontSize: 17),
              ),
            ),
            SizedBox(
              height: 750,
            )
          ]))
        ],
        //   child: Column(
        //     children: [
        //       Align(
        //         alignment: Alignment.centerLeft,
        //         child: Padding(
        //           padding: EdgeInsets.only(top: 20, left: 10),
        //           child: Text(
        //             product.title,
        //             style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        //           ),
        //         ),
        //       ),
        //       SizedBox(height: 20),
        //       Hero(
        //         tag: 'productImage${product.id}',
        //         child: Image.network(
        //           product.imageUrl,
        //           // width: double.infinity,
        //           fit: BoxFit.fitWidth,
        //           height: 300,
        //         ),
        //       ),
        //       SizedBox(height: 30),
        //       Padding(
        //           padding: EdgeInsets.symmetric(horizontal: 10),
        //           child: Align(
        //             alignment: Alignment.centerLeft,
        //             child: Text(
        //               '\$${product.price}',
        //               style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
        //             ),
        //           )),
        //       SizedBox(height: 20),
        //       Padding(
        //           padding: EdgeInsets.symmetric(horizontal: 10),
        //           child: Text(
        //             product.description,
        //             style: TextStyle(fontSize: 17),
        //           ),
        //       ),
        //     ],
        //   ),
      ),
    );
  }
}
