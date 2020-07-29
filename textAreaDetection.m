% This function detects the area of the image where text occurs and stores
% the boundary box as well as the cropped image of each detected text line 
% in a struct.

function  textArea = textAreaDetection(image)
[rows, columns, nColours] = size(image);

%convert to grayscale if it is a colour image
if nColours > 1
    image = rgb2gray(image);
end
    
%smooth the image with gaussan filter (only light smoothing)
img_smooth = imgaussfilt(image,1.1);

%only keep the dark pixel values (if text is too bright it will not work)
%But not making it binary to keep grayscale information at this point!
for i = 1:rows
    for j = 1:columns
        if img_smooth(i,j) < 150
        %if img_smooth(i,j) < 170
            img_smooth(i,j) = img_smooth(i,j);
        else
            img_smooth(i,j) = 0;
        end
    end
end

%% Tried and failed: text is dark pixel value with highest occurance
% [counts,binLocations] = imhist(img_smooth);
 
%if text dark and background bright
%idea: take max of dark part of histogram (this will be text), but only if
%the area is not too big.

% cmax = rows*columns;
% idx=0;
% while cmax > rows*columns/200
%     if idx>0
%         counts_dark(idx) = 0;
%     end
%     [cmax,idx] = max(counts_dark);
% end
% 
% for i = 1:rows
%     for j = 1:columns
%         if img_smooth(i,j) == idx
%             img_smooth(i,j) = idx;
%         else
%             img_smooth(i,j) = 0;
%         end
%     end
% end
% 
% img_smooth = imbinarize(img_smooth, 0.05);
% figure,imshow(img_smooth);title('thresholded');
 

%% Dilation
% do dilation with a horizontal structuring element to connect neighbouring 
% characters
se = strel('line',10, 0);
BW2=img_smooth;
for i=1:5
    BW2 = imdilate(BW2,se);
end

%show dilated image (for report)
imshow(BW2), title('dilated image')

%make binary img
img_smooth = imgaussfilt(BW2,1.2);
binaryImg = imbinarize(img_smooth, 0.25);


%% bounding Boxes
%get bounding boxes of the connected areas
stats = regionprops('table',binaryImg,'BoundingBox','Orientation');

%get bounding boxes with orientation close to zero (text is horizontal)
j = 1;
horizontal_boxes(1,1:4) = 0;
nBoxes = size(stats.BoundingBox);

%show all boxes for presentation:
% figure(30); imshow(image);
% hold on;
% for i = 1:nBoxes(1)
%     rectangle('Position',[stats.BoundingBox(i, 1) stats.BoundingBox(i, 2) stats.BoundingBox(i, 3) stats.BoundingBox(i, 4)],'EdgeColor','red');
%     hold on;
% end
% title('All bounding boxes');
% hold off;

for i = 1:nBoxes(1)
        %don't take the very large or very small boxes
        if stats.BoundingBox(i, 4) < rows*0.3 && stats.BoundingBox(i, 4) > rows*0.01
            if stats.BoundingBox(i, 3) > columns*0.05
                    horizontal_boxes(j, 1:4) = stats.BoundingBox(i, 1:4);
                    j = j+1;
            end
        end
end

%% Tried and failed: Filter with Sobel Masks and then gaussian Bandpass
% % find vertical or horizontal edges (or both)
% 
% %Filter Masks
% F1=[-1 0 1;-2 0 2; -1 0 1];  %vertical edge
% F2=[-1 -2 -1;0 0 0; 1 2 1]; %horizontal edge
% 
% A=double(image);
% I=zeros(size(image));
% 
% for i=1:size(A,1)-2
%     for j=1:size(A,2)-2
%         %Gradient operations
%         Gx=sum(sum(F1.*A(i:i+2,j:j+2)));
%         Gy=sum(sum(F2.*A(i:i+2,j:j+2)));
%                
%         %Magnitude of vector
%          %I(i+1,j+1)=sqrt(Gx.^2+Gy.^2);
%          I(i+1,j+1)=sqrt(Gx.^2);
%          %I(i+1,j+1)=sqrt(Gy.^2);
%        
%     end
% end
% 
% I=uint8(I);
% % figure,imshow(I);title('Filtered Image');
% 
% 
% %find frequency that occurs often (will be text)
% %apply bandpass filter to only let this frequency through
% 
% %gaussian Bandpass filter by combining of a highpass and a lowpass filter
% %with different cutoff frequencies
% A = fft2(double(I)); 
% A1=fftshift(A); 
% [M N]=size(A); % image size
% 
% % Rl=28.9; % filter size parameter lowpass
% % Rh=29; % filter size parameter highpass
% Rl=5; % filter size parameter lowpass
% Rh=5.1; % filter size parameter highpass
% 
% X=0:N-1;
% Y=0:M-1;
% [X Y]=meshgrid(X,Y);
% Cx=0.5*N;
% Cy=0.5*M;
% Lo=exp(-((X-Cx).^2+(Y-Cy).^2)./(2*Rl).^2);
% Loh=exp(-((X-Cx).^2+(Y-Cy).^2)./(2*Rh).^2);
% Hi=1-Loh; % High pass filter=1-low pass filter
% Bp = 1 - (Hi+Lo);
% L = A1.*Bp;
% L1 = ifftshift(L);
% B3 = ifft2(L1);
% 
% figure(5), imshow(B3);
% title('Band pass filtered image');

%% Crop the image

for i=1:size(horizontal_boxes)
    left = ceil(horizontal_boxes(i,1));
    right = left + horizontal_boxes(i,3)-1;
    top = ceil(horizontal_boxes(i,2));
    bottom = top + horizontal_boxes(i,4)-1;
    croppedImage(i).image = image(top:bottom, left:right);
    croppedImage(i).box = horizontal_boxes(i,:);
    croppedImage(i).isTextBox = 1;
end

  figure(8), imshow(croppedImage(1).image);
  textArea = croppedImage;
end