<?php
header('Content-Type: text/html; charset=utf-8');

//Config base de donnée
	$hostname = "localhost";
	$username = "dotclearuser";
	$password = "cleardotstage";
	$database = "dotclear";
	$sql_connect = new MySQLi($hostname, $username, $password, $database);

//Fonction de securite donnees envoye bdd
function securite_bdd($string)
{
	if(ctype_digit($string))
	{
		$string = intval($string);
	}
	else
	{
		$string = addcslashes($string, '%_');
		$string = stripslashes($string);
		$string = strip_tags($string);
		$string = trim($string," ");
		$string = implode("",explode("\\",$string));
		$string = filter_var($string ,FILTER_SANITIZE_STRING, FILTER_FLAG_STRIP_LOW | FILTER_FLAG_STRIP_HIGH);
	}
	return stripslashes(trim($string));
}

//Fonction de test du domaine
function is_valid_domain_name($domain_name)
{
	return (preg_match("/^([a-z\d](-*[a-z\d])*)(\.([a-z\d](-*[a-z\d])*))*$/i", $domain_name)
			&& preg_match("/^.{1,253}$/", $domain_name)
			&& preg_match("/^[^\.]{1,63}(\.[^\.]{1,63})*$/", $domain_name));
}

//recuperation information formulaire
if (isset($_POST['domain']) && !empty($_POST['domain'])) {
	$domain = securite_bdd($_POST['domain']);
	$domain = strtolower($domain);
	$domain = mysqli_real_escape_string($sql_connect,$domain);
	$domain = str_replace('www.','',$domain);
	$domain = 'www.'.$domain;
	if ($sql_connect->connect_error) {
		echo "Non connecté à la base de donnée <br />";
		die();
	}
	else {
		//Comparaison du domaine vers la table BadWords
		$reqwords = "SELECT words FROM dc_badwords WHERE words='$domain';";
		$resultwords = mysqli_query($sql_connect,$reqwords);
		if (mysqli_num_rows($resultwords) < 1)
		{
			//Filtrage des infos > domain_blogs
			if (is_valid_domain_name($domain)) {
				echo "La forme du domaine est valide, le travail continue <br />";

				//Generation du Blog_id
				$idblog = $domain;
				$idblog = str_replace('.', '', $idblog);


				//Generation d'un MD5 HEX 32 Bits pour blog_uid du blog
				$uidblog = md5($idblog);

				//Generation de date de creation blog_datecrea
				$creablogdt = date("Y-m-d H:i:s");

				//Generation blog_URL
				$blogurl = 'http:/\/'.$domain.'/index.php?';

				//Generation du blog_name
				$blogname = $domain.' blog';

				//Generation de la description du blog_desc
				$blogdesc = 'Ceci est le blog '.$domain ;

				//Verifications if_empty isset des variables generes
				if ((isset($idblog) && !empty($idblog)) && (isset($uidblog) && !empty($uidblog)) && (isset($creablogdt) && !empty($creablogdt)) && (isset($blogurl) && !empty($blogurl)) && (isset($blogname) && !empty($blogname)) && (isset($blogdesc) && !empty($blogdesc)))
				{
					//Verification et remplacement des caractères slashs, anti-slashs et pipe
					if ((strpos($domain, '&#47;') !== false) && (strpos($domain, '&#92;') !== false) && (strpos($domain, '&#124;') !== false)) {
					$domain = str_replace('&#37;', '', $domain);
					$domain = str_replace('&#92;', '', $domain);
					$domain = str_replace('&#124;', '', $domain);
					}
					//Requêtes SQL
					$reqverif="SELECT blog_id FROM dc_blog WHERE blog_id='$idblog';";
					$req="INSERT INTO dc_blog (blog_id,blog_uid,blog_creadt,blog_upddt,blog_url,blog_name,blog_desc,blog_status) VALUES ('$idblog','$uidblog','$creablogdt','$creablogdt','$blogurl','$blogname','$blogdesc',1);";
					$reqpublic="INSERT INTO dc_setting VALUES ('public_path','$idblog','system','$idblog/public','string','Path to public directory');";
					$reqpublicurl="INSERT INTO dc_setting VALUES ('public_url','$idblog','system','/$idblog/public','string','URL to public directory');";

					//Exécution SQL de verif
					$resultverifsql = mysqli_query($sql_connect,$reqverif);
					$convertedresultverif = mysqli_fetch_assoc($resultverifsql);
						if ($convertedresultverif['blog_id'] == $idblog){
						echo "Le domaine '$idblog' a déjà été enregistré <br />";
						die();
					}
					else
					{
					//Executions SQL
					$result_sql = mysqli_query($sql_connect,$req);
					$result_sqlpublic = mysqli_query($sql_connect,$reqpublic);
					$result_sqlpublicurl = mysqli_query($sql_connect,$reqpublicurl);
					echo "Le Blog a bien été crée dans notre base de donnée";
					}
				}
				else
				{
				echo "Erreurs dans la génération des variables";
				die();
				}
				//Execution du Script Bash
				echo "<br />";
				echo "<hr />";
				chdir('/home/stagiaire/');
				$output = shell_exec('./newblog.sh '.$domain.' '.$idblog);
				echo $output;
			}
			else
			{
				echo "Le domaine que vous avez rentré est invalide ou mal formulé";
				die();
			}
		}
		else
		{
		echo "Votre domaine comprends des mots interdits par nos services";
		die();
		}
	}
}
else
{
	echo "Vous n'avez pas rentré de domaine dans le précédent formulaire";
	die();
}
?>
