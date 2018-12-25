clear all; clc; close all;

%% read the image
img = imread('cameraman.tif');
%img = rgb2gray(img);
img = double(img)/255;

%% expand input image by a factor of two using bilinear interpolation
img = imresize(img,2,'bilinear');
img = imgaussfilt(img,1);
imshow(img);

%% scales
scales = [0 sqrt(2) 2 2*sqrt(2) 4;
    sqrt(2) 2 2*sqrt(2) 4 4*sqrt(2);
    2 2*sqrt(2) 4 4*sqrt(2) 8;
    2*sqrt(2) 4 4*sqrt(2) 8 8*sqrt(2)];

%% resize to form images for the octaves
img2 = imresize(img,0.5,'bilinear');
img3 = imresize(img2,0.5,'bilinear');
img4 = imresize(img3,0.5,'bilinear');

%% image pyramid
imgPyramid = {img, imgaussfilt(img,scales(1,2)), imgaussfilt(img,scales(1,3)),imgaussfilt(img,scales(1,4)),imgaussfilt(img,scales(1,5));
    imgaussfilt(img2,scales(2,1)), imgaussfilt(img2,scales(2,2)), imgaussfilt(img2,scales(2,3)),imgaussfilt(img2,scales(2,4)),imgaussfilt(img2,scales(2,5));
    imgaussfilt(img3,scales(3,1)),imgaussfilt(img3,scales(3,2)),imgaussfilt(img3,scales(3,3)),imgaussfilt(img3,scales(3,4)),imgaussfilt(img3,scales(3,5));
    imgaussfilt(img4,scales(4,1)),imgaussfilt(img4,scales(4,2)),imgaussfilt(img4,scales(4,3)),imgaussfilt(img4,scales(4,4)),imgaussfilt(img4,scales(4,5))};

%% %show the pyramid
% for i=1:1:4
%     figure;
%     for j=1:1:5
%     subplot(3,3,j);
%     imshow(imgPyramid{i,j});
%     end
% end

%% DOG pyramid
dogPyramid = {imgPyramid{1,2}-imgPyramid{1,1}, imgPyramid{1,3}-imgPyramid{1,2}, imgPyramid{1,4}-imgPyramid{1,3},imgPyramid{1,5}-imgPyramid{1,4};
    imgPyramid{2,2}-imgPyramid{2,1}, imgPyramid{2,3}-imgPyramid{2,2}, imgPyramid{2,4}-imgPyramid{2,3},imgPyramid{2,5}-imgPyramid{2,4};
    imgPyramid{3,2}-imgPyramid{3,1}, imgPyramid{3,3}-imgPyramid{3,2}, imgPyramid{3,4}-imgPyramid{3,3},imgPyramid{3,5}-imgPyramid{3,4};
    imgPyramid{4,2}-imgPyramid{4,1}, imgPyramid{4,3}-imgPyramid{4,2}, imgPyramid{4,4}-imgPyramid{4,3},imgPyramid{4,5}-imgPyramid{4,4}};

%% %show the pyramid
% for i=1:1:4
%     figure;
%     for j=1:1:4
%     subplot(2,2,j);
%     imshow(dogPyramid{i,j});
%     end
% end

%% local max and min
%x,y,value,octave no,column in octav, scale
localMax = [];
localMin = [];

for i=1:1:4 %for octav
    for j=2:1:3 %col in octav
        myImg = double(dogPyramid{i,j});
        upImg = double(dogPyramid{i,j-1});
        downImg = double(dogPyramid{i,j+1});
        rows = size(myImg,1);
        cols = size(myImg,2);
        for k=2:1:rows-1 %row of image
            for l=2:1:cols-1 %col of image
                
                %check neighbors
                value = myImg(k,l);
                neighbors = [myImg(k-1,l-1) myImg(k-1,l) myImg(k-1,l+1) myImg(k,l-1) myImg(k,l+1) myImg(k+1,l-1) myImg(k+1,l) myImg(k+1,l+1) ...
                    upImg(k-1,l-1) upImg(k-1,l) upImg(k-1,l+1) upImg(k,l-1) upImg(k,l) upImg(k,l+1) upImg(k+1,l-1) upImg(k+1,l) upImg(k+1,l+1) ...
                    downImg(k-1,l-1) downImg(k-1,l) downImg(k-1,l+1) downImg(k,l-1) downImg(k,l) downImg(k,l+1) downImg(k+1,l-1) downImg(k+1,l) downImg(k+1,l+1)];
                ismax = 1;
                ismin = 1;
                for m=1:1:26
                    if ismax ==1 || ismin == 1
                        if value <= neighbors(m)
                            ismax = 0;
                        end
                        if value >= neighbors(m)
                            ismin = 0;
                        end
                    else
                        break;
                    end
                end
                
                %it is a max
                if ismax == 1 && ismin == 0
                    localMax = [localMax; k l value i j scales(i,j)];
                end
                %it is a min
                if ismin == 1 && ismax ==0
                    localMin = [localMin; k l value i j scales(i,j)];
                end
            end
        end
    end
end

localMax = [localMax;localMin];

%% Taylor Expansion for subpixel maxima/minima
[maxRow, maxCol] = size(localMax);
newLocalMax = [];
for a=1:maxRow
    %Hessian = zeros(3,3);
    pointmax = localMax(a,:);
    pointmax = double(pointmax);
    image = dogPyramid{pointmax(4),pointmax(5)}(pointmax(1),pointmax(2));
    
    Dx = (dogPyramid{pointmax(4),pointmax(5)}(pointmax(1),pointmax(2)+1)...
        - dogPyramid{pointmax(4),pointmax(5)}(pointmax(1),pointmax(2)-1))/2;
    
    Dy = (dogPyramid{pointmax(4),pointmax(5)}(pointmax(1)+1,pointmax(2))...
        - dogPyramid{pointmax(4),pointmax(5)}(pointmax(1)+1,pointmax(2)))/2;
    
    Ds = (dogPyramid{pointmax(4),pointmax(5)+1}(pointmax(1),pointmax(2))...
        - dogPyramid{pointmax(4),pointmax(5)+1}(pointmax(1),pointmax(2)))/2;
    
    Dxx = dogPyramid{pointmax(4),pointmax(5)}(pointmax(1),pointmax(2)+1)...
        + dogPyramid{pointmax(4),pointmax(5)}(pointmax(1),pointmax(2)-1)- 2*image;
    
    Dyy = dogPyramid{pointmax(4),pointmax(5)}(pointmax(1)+1,pointmax(2))...
        + dogPyramid{pointmax(4),pointmax(5)}(pointmax(1)-1,pointmax(2))- 2*image;
    
    Dss = dogPyramid{pointmax(4),pointmax(5)+1}(pointmax(1),pointmax(2))...
        + dogPyramid{pointmax(4),pointmax(5)-1}(pointmax(1),pointmax(2))- 2*image;
    
    Dxy = (dogPyramid{pointmax(4),pointmax(5)}(pointmax(1)+1,pointmax(2)+1)...
        -  dogPyramid{pointmax(4),pointmax(5)}(pointmax(1)+1,pointmax(2)-1)...
        -  dogPyramid{pointmax(4),pointmax(5)}(pointmax(1)-1,pointmax(2)+1)...
        +  dogPyramid{pointmax(4),pointmax(5)}(pointmax(1)-1,pointmax(2)-1))/4;
    
    Dxs = (dogPyramid{pointmax(4),pointmax(5)+1}(pointmax(1),pointmax(2)+1)...
        -  dogPyramid{pointmax(4),pointmax(5)+1}(pointmax(1),pointmax(2)-1)...
        -  dogPyramid{pointmax(4),pointmax(5)-1}(pointmax(1),pointmax(2)+1)...
        +  dogPyramid{pointmax(4),pointmax(5)-1}(pointmax(1),pointmax(2)-1))/4;
    
    Dys = (dogPyramid{pointmax(4),pointmax(5)+1}(pointmax(1)+1,pointmax(2))...
        -  dogPyramid{pointmax(4),pointmax(5)+1}(pointmax(1)-1,pointmax(2))...
        -  dogPyramid{pointmax(4),pointmax(5)-1}(pointmax(1)+1,pointmax(2))...
        +  dogPyramid{pointmax(4),pointmax(5)-1}(pointmax(1)-1,pointmax(2)))/4;
    
    Hessian = [Dxx Dxy Dxs; Dxy Dyy Dys; Dxs Dxy Dss];
    Hessian = double(Hessian);
    Deriv = [Dx;Dy;Ds];
    Deriv = double(Deriv);
    offset = -inv(Hessian)*Deriv;
    offset = double(offset);
    %Eliminating edge responses
    Hessian2 = [Dxx Dxy; Dxy Dyy];
    edgeResThres = ((10+1)^2)/10;
    myMetric = ((trace(Hessian2))^2)/det(Hessian2);
    
    if (myMetric < edgeResThres)
        if (abs(offset(1)) < 0.5 && abs(offset(2)) < 0.5 && abs(offset(3)) < 0.5)
            value = double(pointmax(3)) + double((1/2)*(Deriv'*offset));
            value = double(value);
            pointmax = double(pointmax);
            if(abs(value) > 0.03)
                newLocalMax = [newLocalMax; pointmax(1)+offset(1) pointmax(2)+offset(2) pointmax(3) pointmax(4) pointmax(5) pointmax(6)+offset(3)];
            end
        end
    end
end


%% Orientation Assignment

%the eliminated keypoints are stored in: newLocalMax

%First, the gradient directions and magnitudes should be computed for the
%scale space.

imgPyramid = {img, imgaussfilt(img,scales(1,2)), imgaussfilt(img,scales(1,3)),imgaussfilt(img,scales(1,4)),imgaussfilt(img,scales(1,5));
    imgaussfilt(img2,scales(2,1)), imgaussfilt(img2,scales(2,2)), imgaussfilt(img2,scales(2,3)),imgaussfilt(img2,scales(2,4)),imgaussfilt(img2,scales(2,5));
    imgaussfilt(img3,scales(3,1)),imgaussfilt(img3,scales(3,2)),imgaussfilt(img3,scales(3,3)),imgaussfilt(img3,scales(3,4)),imgaussfilt(img3,scales(3,5));
    imgaussfilt(img4,scales(4,1)),imgaussfilt(img4,scales(4,2)),imgaussfilt(img4,scales(4,3)),imgaussfilt(img4,scales(4,4)),imgaussfilt(img4,scales(4,5))};

gradient_magnitude = {};
gradient_orientation = {};

for i=1:1:4
    for j=1:1:5
        myImg = imgPyramid{i,j};
        myImg = double(myImg);
        [rows, cols, ch] = size(myImg);
        gradientMag = zeros(rows,cols);
        gradientMag = double(gradientMag);
        orientation = zeros(rows,cols);
        orientation = double(orientation);
        for k=2:1:rows-2
            for m=2:1:cols-2
                magn = sqrt((myImg(k+1,m)-myImg(k-1,m))^2 + (myImg(k,m+1)-myImg(k,m-1))^2 );
                angle = atan2d((myImg(k,m+1)-myImg(k,m-1)),(myImg(k+1,m)-myImg(k-1,m)));
                angle = angle + 180;
                gradientMag(k,m) = magn;
                orientation(k,m) = angle;
            end
        end
        
        gradient_magnitude{end+1} = gradientMag;
        gradient_orientation{end+1} = orientation;
    end
end


% fspecial('gaussian', size, sigma)
% Now, orientation assignment
%x,y,value,octave no,column in octav, scale, binNumber(for orientation)
interest_points = []; %unique ones
for i=1:1:size(newLocalMax,1)
    histogram = zeros(1,36);
    x = newLocalMax(i,1);
    y = newLocalMax(i,2);
    value = newLocalMax(i,3);
    octaveRow = newLocalMax(i,4);
    octaveCol = newLocalMax(i,5);
    sigma = newLocalMax(i,6);
    
    %the image this point lies on and pad
    grad_mag_img = gradient_magnitude{(octaveRow-1)*5 + octaveCol};
    grad_orient_img = gradient_orientation{(octaveRow-1)*5 + octaveCol};
    grad_mag_img = padarray(grad_mag_img,[50 50],'both');
    grad_orient_img = padarray(grad_orient_img,[50 50],'both');
    
    %the kernel we will use for gaussian weigted histogram
    ksize = uint32(1.5*sigma);
    if mod(ksize,2) ==0
        ksize = ksize +1;
    end
    ksize = double(ksize);
    kernel = fspecial('gaussian', ksize, sigma);
    
    k = (ksize-1)/2;
    
    xint = uint32(x);
    yint = uint32(y);
    
    grad_mag_img_window = grad_mag_img(xint+50-k:xint+50+k,yint+50-k:yint+50+k);
    grad_orient_img_window = grad_orient_img(xint+50-k:xint+50+k,yint+50-k:yint+50+k);
    
    %compute the histogram
    for j=1:1:size(grad_orient_img_window)
        for k=1:1:size(grad_orient_img_window)
            angle = grad_orient_img_window(j,k);
            magnitude = grad_mag_img_window(j,k);
            binNumber = floor(angle/10)+1;
            histogram(binNumber) = histogram(binNumber) + kernel(j,k)*magnitude;
        end
    end
    
    %find the orientation
    max_value = max(histogram);

    for n=1:1:36
        if histogram(1,n) == max_value || histogram(1,n) >= (max_value*(8/10))
            interest_points = [interest_points;x y value octaveRow octaveCol sigma n];
        end
    end
end



