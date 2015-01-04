      function S3ToolsClass(bucketName) {
        var _handle_progress = null;
        var _handle_success  = null;
        var _handle_error    = null;
        var _file_name       = null;
        this.file_url_on_s3  = null;
        var s3_bucket_url    = 'https://' + bucketName + '.s3.amazonaws.com/';
        var s3_folder_prefix = 'graeters/direct_uploads/';
 
        this.uploadFile = function(file, creds, progress, success, error) {
          _handle_progress = progress;
          _handle_success  = success;
          _handle_error    = error;
          _file_name       = file.name;
          this.file_url_on_s3   = s3_bucket_url + s3_folder_prefix + file.name;

          AWSKeyId = creds.key;
          policy = creds.policy;
          signature = creds.signature;
 
          var fd = new FormData();
          fd.append('key', s3_folder_prefix + file.name);
          fd.append('AWSAccessKeyId', AWSKeyId);
          fd.append('acl', 'public-read');
          fd.append('policy', policy);
          fd.append('signature', signature);
          fd.append('Content-Type', file.type); 
          fd.append('x-amz-storage-class', "REDUCED_REDUNDANCY"); 
          fd.append("file",file);
 
          var xhr = new XMLHttpRequest();
          xhr.upload.addEventListener("progress", uploadProgress, false);
          xhr.addEventListener("load", uploadComplete, false);
          xhr.addEventListener("error", uploadFailed, false);
          xhr.addEventListener("abort", uploadCanceled, false);
          xhr.open('POST', s3_bucket_url, true); //MUST BE LAST LINE BEFORE YOU SEND
          xhr.setRequestHeader('Access-Control-Allow-Origin', '*');
          xhr.send(fd);
        }
 
        function uploadProgress(evt) {
          
            console.log(evt);
          if (evt.lengthComputable) {
            var percentComplete = Math.round(evt.loaded * 100 / evt.total);
            _handle_progress(percentComplete);
          }
        }
 
        function uploadComplete(evt) {
          if (evt.target.responseText == "") {
            _handle_success(_file_name);
          } else {
            _handle_error(evt.target.responseText);
          }
        }
 
        function uploadFailed(evt) {
          _handle_error("There was an error attempting to upload the file." + evt);
          this.file_url_on_s3 = null;
        }
 
        function uploadCanceled(evt) {
          _handle_error("The upload has been canceled by the user or the browser dropped the connection.");
          this.file_url_on_s3 = null;
        }
      }