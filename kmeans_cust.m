input_dataset=dataset;
k=5;
num_cores=10;
D=size(input_dataset,2);
kmeans_centers_init=randn(k,D);
kmeans_centers=kmeans_centers_init;
loss_list=[];

%% Centralized_kmeans
for i=1:20
    [kmeans_centers,weights_i,loss]=kmeans_iter(input_dataset,kmeans_centers, ones(size(input_dataset,1),1));
    loss_list=[loss_list loss];
end


%% Distributed_kmeans -- setup
distribution_list=rand(1,num_cores);
distribution_list=int32(distribution_list.*(size(input_dataset,1)/sum(distribution_list)));
distribution_list=[0 distribution_list];
dist_list=randperm(size(input_dataset,1));
data_list_i=[];
for i=1:num_cores
    data_list_i{i}=data_list(1,distribution_list(1,i):distribution_list(1,i+1));
end

%% Distributed kmeans
all_centers=zeros(num_cores*k,D);
all_weights=zeros(num_cores*k,1);
weights_common_data=all_weights;
common_data=all_centers;
outer_iter=4;
inner_iter=1;
all_centers=repmat(kmeans_center_init,[num_nodes 1]);
for i=1:20
    for j=1:num_nodes
        start_index=(j-1)*k+1;
        end_index=j*k;
        select_centers=cumsum(ones(1,size(common_data,1)));
        select_centers(start_index:end_index,1)=[];
        data_i=[input_dataset(data_list{i},:);common_data(select_centers,:)];
        point_weight_i=[ones(size(input_dataset,1),1);all_weights(select_centers,1)];
        [all_centers(start_index:end_index,:),all_weights(start_index:end_index,1),loss]=kmeans_iter(data_i,all_centers(start_index:end_index,:),point_weight_i);
        loss_list=[loss_list loss];
    end
end