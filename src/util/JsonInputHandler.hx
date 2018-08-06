package util;

import sys.io.File;
import sys.FileSystem;
import haxe.io.Bytes;

using StringTools;

class JsonInputHandler{

    public var bucketFiles:Array<{name:String, data:Bytes}> = [];

    var baseDir:String;

    public function new(baseDir:String){
        this.baseDir = baseDir;        
    }


    public function parseObject(obj:Dynamic, config:Dynamic):Void{
        var fields = Reflect.fields(obj);

        for(fName in fields){
            var field = Reflect.field(obj, fName);

            if(Std.is(field, String)){
                Reflect.setField(obj, fName, StringTools.replace(field, "&&bucketName&&", config.bucketName));
            }
            else if(Reflect.isObject(field)){
                parseObject(field, config);
            }
        }
    }

    public function handle(str:String):Dynamic{
        var template = new util.Template(str);
        var output = template.execute({}, this);
        var config = haxe.Json.parse(output);

        parseObject(config, config);
        return config;
    }

    function file(resolve:String->Dynamic, path:String):String{
        if(!FileSystem.exists(baseDir + path)) throw "File Not Found: " + baseDir + path;
        var content = File.getContent(baseDir + path);
        var template = new util.Template(content);
        return template.execute({}, this);
    }

    function zipBase64(resolve:String->Dynamic, path:String):String{
        var zip = new util.Zip();
        var name = path.split("/").pop();
        zip.add(baseDir + path, name);
        return haxe.crypto.Base64.encode(zip.getBytes());
    }

    function lambdaCode(resolve:String->Dynamic, path:String, version=""){
        var zip = new util.Zip();
        var name = path.split("/").pop();
        zip.add(baseDir + path, name);
        bucketFiles.push({name:name + version + ".zip", data:zip.getBytes()});
        return '{"S3Bucket":"&&bucketName&&", "S3Key":"' + name + version + '.zip"}';
    }

    function urlEncode(resolve:String->Dynamic, str:String):String{
        return str.urlEncode();
    }

    function quoteEscape(resolve:String->Dynamic, str:String):String{
        return str.replace("\"", "\\\"");
    }

    function base64File(resolve:String->Dynamic, path:String):String{
        var content = file(resolve, path);
        return haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(content));
    }
}