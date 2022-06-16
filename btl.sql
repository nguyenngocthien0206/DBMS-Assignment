-- add new product
create proc sp_add_new_product
@product_id int,
@product_name varchar(255),
@brand_id int,
@category_id int,
@model_year smallint,
@list_price decimal(10,2)
as
set xact_abort on
begin transaction
if @product_id in (select product_id from production.products)
	print 'Product id has existed.'
if @brand_id not in (select brand_id from production.brands)
	print 'Brand id does not exist.'
if @category_id not in (select category_id from production.categories)
	print 'Category id does not exist.'
if @list_price <= 0
	begin
		print 'Invalid list price.'
		return
	end
set identity_insert production.products on
insert into production.products(product_id,product_name,brand_id,category_id,model_year,list_price)
values (@product_id,@product_name,@brand_id,@category_id,@model_year,@list_price)
set identity_insert production.products off
commit
exec sp_add_new_product 325,'Trek Checkpoint ALR Frameset - 2023',9,7,2023,3399.99

-- update list price
create proc sp_update_list_price
@product_id int,
@list_price decimal(10,2)
as
set xact_abort on
begin transaction
if @product_id not in (select product_id from production.products)
	print 'Product id does not exist.'
if @list_price <= 0
	begin
		print 'Invalid list price.'
		return
	end
update production.products
set list_price = @list_price
where product_id = @product_id
commit
exec sp_update_list_price 324,3099.99

-- add new order
create proc sp_add_new_order
@order_id int,
@customer_id int,
@store_id int,
@staff_id int
as
set xact_abort on
begin transaction
if @order_id in (select order_id from sales.orders)
	print 'Order id has existed.'
set xact_abort off
if @customer_id not in (select customer_id from sales.customers)
	begin
	set identity_insert sales.customers on
	insert into sales.customers(customer_id,first_name,last_name,email)
	values (@customer_id,'a','b','c@gmail.com')
	set identity_insert sales.customers off
	end
set xact_abort on
if @store_id not in (select store_id from sales.stores)
	print 'Store id does not exist.'
if @staff_id not in (select staff_id from sales.staffs)
	print 'Staff id does not exist.'
set identity_insert sales.orders on
insert into sales.orders(order_id,customer_id,order_status,order_date,required_date,store_id,staff_id)
values(@order_id,@customer_id,1,getdate(),dateadd(dd,3,getdate()),@store_id,@staff_id)
set identity_insert sales.orders off
commit
exec sp_add_new_order 1,1900,3,8

-- add new order detail
create proc sp_add_new_order_detail
@order_id int,
@item_id int,
@product_id int,
@quantity int,
@discount decimal(4,2)
as
set xact_abort on
begin transaction 
if @order_id not in (select order_id from sales.orders)
	print 'Order id does not exist.'
if @item_id in (select item_id from sales.order_items where order_id = @order_id)
	print 'Item id has existed.'
if @product_id not in (select product_id from production.products)
	print 'Product does not exist.'
if (select quantity from production.stocks where product_id = @product_id and store_id = (select store_id from sales.orders where order_id = @order_id)) = 0
	begin
		print 'Quantity = 0.'
		return
	end
if (@quantity <= 0) or (@quantity > (select quantity from production.stocks where product_id = @product_id and store_id = (select store_id from sales.orders where order_id = @order_id)))
	begin
		print 'Invalid quantity.'
		return
	end
if @discount < 0 
	begin
		print 'Invalid discount'
		return
	end
insert into sales.order_items(order_id,item_id,product_id,quantity,list_price,discount)
values (@order_id,@item_id,@product_id,@quantity,(select list_price from production.products where product_id = @product_id),@discount)
commit
begin transaction
update production.stocks
set quantity = quantity - @quantity
where product_id = @product_id and store_id = (select store_id from sales.orders where order_id = @order_id)
commit
drop proc sp_add_new_order_detail
exec sp_add_new_order_detail 1617,4,1,1,0.2



