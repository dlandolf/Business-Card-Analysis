
%This function takes bounding box and cropped image with text as input and
%separates the characters inside each text box

function  separateCharacter = separateCharacters(text_image)

dimBoxes = size(text_image);
nBoxes = dimBoxes(2);

%% make binary image
for i=1:nBoxes
    text_image(i).binaryImage = imbinarize(text_image(i).image,0.6);
    %text_image(i).binaryImage = imbinarize(text_image(i).image,0.9);
    
    %need to invert it because letters need to be 1 and background 0
    text_image(i).binaryImage = 1-text_image(i).binaryImage;
end

%% Failed: opening to separate characters, because some may be "overlapping"
%    se = strel('cube',5);
%    
%    for i=1:nBoxes
%        erodedImg(i).image = imerode(text_image(i).binaryImage,se);
%        openedImg(i).image = imdilate(erodedImg(i).image,se);
%    end
% %    figure, imshow(openedImg(2).image);
%      %figure, imshow(text_image(2).binaryImage);

%% closing to have "closed" letters
se = strel('cube',3);
   
   for i=1:nBoxes
       erodedImg(i).image = imdilate(text_image(i).binaryImage,se);
       closedImg(i).image = imerode(erodedImg(i).image,se);
   end
    %closedImg(i).image = text_image(i).binaryImage
%% vertical projection

if nBoxes>0
    text_image(1).characters(1).letterImg=0;
    text_image(1).characters(1).box=[0,0,0,0];
end
    
for i=1:nBoxes
    kshift = 0;
    horizontalProfile = sum(closedImg(i).image, 1);
    
    if i == 1
        graphProfile(1:10,:) = [horizontalProfile;horizontalProfile;horizontalProfile;horizontalProfile;horizontalProfile;horizontalProfile;horizontalProfile;horizontalProfile;horizontalProfile;horizontalProfile];
        figure(12), imshow(graphProfile);
    end

    % 0 where there is background, 1 where there are letters
    letterLocations = horizontalProfile > 0; 

    % Find edges
    d = diff(letterLocations);
    startingColumns = find(d>0);
    endingColumns = find(d<0);
   
    %if there is only one "letter" in the textbox it is most likely no textbox
    if length(startingColumns)>1
        
        %if the letter touches the boundary of the box, the size of
        %starting and ending columns don't match
        if length(startingColumns) > length(endingColumns)
            addendsize = size(text_image(i).binaryImage);
            endingColumns(length(endingColumns)+1) = addendsize(2);
          else if length(startingColumns) < length(endingColumns)
                  %shift all starting columns one to the back
                  startingColumns(length(startingColumns)+1) = 1;
                  startingColumns = circshift(startingColumns,1,1);    
            else if endingColumns(1) < startingColumns(1) %starts (and ends) with the "wrong one"
                    startingColumns(length(startingColumns)+1) = 1;
                    startingColumns = circshift(startingColumns,1,1);
                    addendsize = size(text_image(i).binaryImage);
                    endingColumns(length(endingColumns)+1) = addendsize(2);
                end
              end
        end
        
        if length(startingColumns) == length(endingColumns)
            % Extract each region
            %if I want to add k-shift need WHILE loop...
            for k = 1 : length(startingColumns)

              %store location of each letter
              text_image(i).characters(k+kshift).box(:) = [text_image(i).box(1) + startingColumns(k), text_image(i).box(2), abs(endingColumns(k)-startingColumns(k)), text_image(i).box(4)];

              %store image of each letter
              text_image(i).characters(k+kshift).letterImg = text_image(i).binaryImage(:, startingColumns(k):endingColumns(k));

              
              %if letter is too wide there is probably more than one letter combined
              if text_image(i).characters(k+kshift).box(3)/text_image(i).characters(k+kshift).box(4)>1.2
                  
                  %smooth first
                  img_smooth = imgaussfilt(text_image(i).characters(k+kshift).letterImg,1.3);
                  %figure(8); imshow(img_smooth);
                  img_smooth = imbinarize(img_smooth,0.6);
                  %figure(9); imshow(img_smooth);
                  
                  %opening to separate characters, because some may be "overlapping"
                  %choose 'line' to seperate more in horizontal direction
                  se = strel('line',3,0);
                  erodedImg = imerode(img_smooth,se);
                  openedImg = imdilate(erodedImg,se);
                  %openedImg = erodedImg;
                  
                  %openedImg = img_smooth;
    
                  %do the same vertical projection as before
                  horizontalProfileAdd = sum(openedImg, 1);
                  
                  %figure(10); imshow(horizontalProfileAdd);
                  
                  letterLocationsAdd = horizontalProfileAdd > 0;
                  dAdd = diff(letterLocationsAdd);
                  startingColumnsAdd = find(dAdd>0);
                  endingColumnsAdd = find(dAdd<0);
                  if length(startingColumnsAdd)>0 && length(endingColumnsAdd)>0
                      if length(startingColumnsAdd) > length(endingColumnsAdd)
                          addendsize = size(text_image(i).characters(k+kshift).letterImg);
                          endingColumnsAdd(length(endingColumnsAdd)+1) = addendsize(2);
                      else if length(startingColumnsAdd) < length(endingColumnsAdd)
                              %shift all starting columns one to the back
                              startingColumnsAdd(length(startingColumnsAdd)+1) = 1;
                              startingColumnsAdd = circshift(startingColumnsAdd,1,1);  
                           else if endingColumnsAdd(1) < startingColumnsAdd(1) %starts (and ends) with the "wrong one"
                                    startingColumnsAdd(length(startingColumnsAdd)+1) = 1;
                                    startingColumnsAdd = circshift(startingColumnsAdd,1,1);
                                    addendsize = size(text_image(i).characters(k+kshift).letterImg);
                                    endingColumnsAdd(length(endingColumnsAdd)+1) = addendsize(2);
                                end
                          end
                      end
                  end
      
                  %store location of each letter
                  if length(startingColumnsAdd)>1 && length(endingColumnsAdd) == length(startingColumnsAdd)
                      %first write new values in temporary variable
                      for add = 1 : length(startingColumnsAdd)
                          if add == 1
                              temp_image.characters(k+kshift + add-1).box(:) = [text_image(i).characters(k+kshift).box(1), text_image(i).characters(k+kshift).box(2), abs(endingColumnsAdd(add)-startingColumnsAdd(add)), text_image(i).characters(k+kshift).box(4)];

                              temp_image.characters(k+kshift + add-1).letterImg = text_image(i).characters(k+kshift).letterImg(:, startingColumnsAdd(add):endingColumnsAdd(add));
                          else
                              temp_image.characters(k+kshift + add-1).box(:) = [text_image(i).characters(k+kshift).box(1) + startingColumnsAdd(add), text_image(i).characters(k+kshift).box(2), abs(endingColumnsAdd(add)-startingColumnsAdd(add)), text_image(i).characters(k+kshift).box(4)];
                              %store image of new letters
                              temp_image.characters(k+kshift + add-1).letterImg = text_image(i).characters(k+kshift).letterImg(:, startingColumnsAdd(add):endingColumnsAdd(add));
                              
                          end
                            %figure(11); imshow(temp_image.characters(k+kshift + add-1).letterImg);
                      end
                      
                      %put new values in actual data
                      for add = 1 : length(startingColumnsAdd)
                              text_image(i).characters(k+kshift + add-1).box(:) = temp_image.characters(k+kshift + add-1).box(:);
                              text_image(i).characters(k+kshift + add-1).letterImg = temp_image.characters(k+kshift + add-1).letterImg;
                      end
                      %need to shift all k's about the amount of new letters
                      kshift = kshift + length(startingColumnsAdd) - 1;
                  end
              end

              
            end
        else
            %if startingColumns not = ending columns a mistake happend
            disp('Separation of letters in one textfield failed.')
            %display box of the whole textline
            text_image(i).characters(1).box = text_image(i).box;
            text_image(i).characters(1).letterImg = text_image(i).binaryImage;
        end
    else
        text_image(i).isTextBox = 0;
    end
    
end
 %figure, imshow(text_image(1).characters(1).letterImg);
 
 %% do also horizontal projection of individual letters for recognition

 nBoxes = size(text_image);
 if nBoxes(2)>1
     for i = 1:nBoxes(2)
            nCharacters = size(text_image(i).characters);
            for j = 1:nCharacters(2)
                smooth_img = imgaussfilt(text_image(i).characters(j).letterImg,[1 2]);
                %smooth_img=text_image(i).characters(j).letterImg;
                smooth_img = imbinarize(smooth_img,0.5);
                %figure(12); imshow(smooth_img);
                verticalProfile = sum(smooth_img, 2);
                letterLocations = verticalProfile > 0; 
                d = diff(letterLocations);
                startingRow = find(d>0);
                endingRow = find(d<0);
                if length(startingRow)==0
                    startingRow(1)=1; 
                end
                if length(endingRow)==0
                    lettersize = size(text_image(i).characters(j).letterImg);
                    endingRow(1)=lettersize(1); 
                end

                  if length(startingRow)>=1
                      if length(startingRow) > length(endingRow)
                            addendsize = size(text_image(i).characters(j).letterImg);
                            endingRow(length(endingRow)+1) = addendsize(1);
                        else if length(startingRow) < length(endingRow)
                                  %shift all starting columns one to the back
                                  startingRow(length(startingRow)+1) = 1;
                                  startingRow = circshift(startingRow,1,1);  
                              else if endingRow(1) < startingRow(1) %starts (and ends) with the "wrong one"
                                        startingRow(1) = 1;
                                        %startingRow(length(startingRow)+1) = 1;
                                        %startingRow = circshift(startingRow,1,1);
                                        addendsize = size(text_image(i).characters(j).letterImg);
                                        endingRow(length(endingRow)+1) = addendsize(1);
                                   end
                            end
                      end

                      %adjust height and y position of letterboxes
                      text_image(i).characters(j).box(:) = [text_image(i).characters(j).box(1), text_image(i).characters(j).box(2) + (startingRow(1)-1), text_image(i).characters(j).box(3), abs(endingRow(length(endingRow))-startingRow(1))];

                      %store cropped image of each letter
                      text_image(i).characters(j).letterImg = text_image(i).characters(j).letterImg(startingRow(1):endingRow(length(endingRow)), :);
                  end

            end

     end
 end
 
 
 %% output individual characters 
   separateCharacter = text_image;
end