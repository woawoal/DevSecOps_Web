<?php

include './../db/maindb.php';


    if(isset($_POST['username'])){

        $username = htmlspecialchars($_POST['username']);

        if($username == null){

            echo "null";

        }else{

            $sql = "SELECT username FROM users WHERE username='$username'";
            $result = $conn->query($sql);

            if($result->num_rows > 0){

                echo "true";

            }else{

                echo "false";

        }



        }
        
        

    }


?>