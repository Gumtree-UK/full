/** Convert the keyvalue from dart5 to dart6 form */
public with sharing class DARTEvaluator {

	
	public static List<CustomCriteriaSet> convertToCritSet(String oldForm5)
	{
			
			Functionalizer fn = new Functionalizer();
			String formula=fn.functionalize(oldForm5);
			System.debug('____________>'+formula);
			Parser ps = new Parser();
			Node node=ps.parse(formula);
			
			//Parser.dump(node,2);
			
			Evaluator eval = new Evaluator();
					
			eval.distribute(node.getParent(), node);
			
			Node newNode = node.getParent().getLeft();
			
			ps.dump(newNode, 1);
			
			List<CustomCriteriaSet> lc = new List<CustomCriteriaSet>();
			
			eval.evaluate(newNode,lc,null);
			
			// List<CustomCriteria>
			// CustomCriteria { List<Node> criteria;}
			// if criteria > 1 => AND operator
			// if criteria = 1 no operator
			
			
			//System.debug('-------------->The Result is:'+node);
			//System.debug('-------------->The Result lc is:'+lc);
			
			return lc;
	}
		 
	public class Condition {
		
		private String parameter;
		private String value;
		private String operator;
		
		public String getParameter() {
			return parameter;
		}
		public void setParameter(String parameter) {
			this.parameter = parameter;
		}
		public String getValue() {
			return value;
		}
		public void setValue(String value) {
			this.value = value;
		}
		public String getOperator() {
			return operator;
		}
		public void setOperator(String operator) {
			this.operator = operator;
		}
	
	}
	
	public class CustomCriteriaSet {
	
		private List<Condition> criterion = new List<Condition>();
	
		public List<Condition> getCriterion() {
			return criterion;
		}
	
		public void setCriterion(List<Condition> criterion) {
			this.criterion = criterion;
		}
	
	}
	
	
	public class Evaluator {
		
		
		public void evaluate(Node node, List<CustomCriteriaSet> lcss, CustomCriteriaSet ccs) {
			
			 if (node!=null) {
				if (node.getName().equalsIgnoreCase('EQ')) {
					
					Condition c = new Condition();
					c.setParameter(node.getLeft().getName());
					c.setValue(node.getRight().getName());
					
					c.setOperator('=');  //me
					CustomCriteriaSet ccs2 = null;
					
					if (ccs==null) {
						ccs2 = new CustomCriteriaSet();
						ccs = ccs2;
						lcss.add(ccs2);		
					}
					
					ccs.getCriterion().add(c);
			
					
					
				}
				else if (node.getName().equalsIgnoreCase('OR')) {
					
					CustomCriteriaSet ccs1 = new CustomCriteriaSet();
					evaluate(node.getLeft(), lcss,ccs1) ;
					if (ccs1.getCriterion().size()>0)
					lcss.add(ccs1);	
					
					
					CustomCriteriaSet ccs2 = new CustomCriteriaSet();
					evaluate(node.getRight(), lcss,ccs2) ;
					if (ccs2.getCriterion().size()>0)
					lcss.add(ccs2);					
	
					
				}
				else if (node.getName().equalsIgnoreCase('AND')) {
					
					CustomCriteriaSet ccs2 = null;
					if (ccs==null) {
						ccs2 = new CustomCriteriaSet();
						ccs = ccs2;
						lcss.add(ccs2);		
					}
					
					evaluate(node.getLeft(), lcss,ccs);
					evaluate(node.getRight(), lcss,ccs) ;
					
				}else if (node.getName().equalsIgnoreCase('')) {
					evaluate(node.getLeft(), lcss,ccs);
					evaluate(node.getRight(), lcss,ccs);
				}
				
			 }
			
		}
		
		
		public  void distribute(Node root, Node node){
	
					
			 if (node!=null) {
				 distribute(root,node.getLeft());
				 distribute(root,node.getRight());
				
				// 
				if (node.getName().equals('AND')) {
					
					//  (a + b) * c -> a*c + b*c
					Node left = node.getLeft();
					Node right = node.getRight();
					
					if (left.getName().equals('OR') ) {
						
						
						Node a = left.getLeft();
						Node b = left.getRight();
						Node c = right;
						
						
						Node newparentnode = new Node('OR');
						
				        Node newleftnode = new Node('AND');
				        newleftnode.setLeft(a);
				        newleftnode.setRight(c);
				        
				        Node newrightnode = new Node('AND');
				        newrightnode.setLeft(b);
				        newrightnode.setRight(c);
				        
				        newparentnode.setLeft(newleftnode);
				        newparentnode.setRight(newrightnode);
				        
						if (node.getParent()!=null && node.getParent().getLeft()!=null && node.getParent().getLeft()==node) {
							node.getParent().setLeft(newparentnode);
						}
						else {
							node.getParent().setRight(newparentnode);
						}
						
						distribute(root,newparentnode);
						
					}
					else if (right.getName().equals('OR') ) {
			
						 // a * (b + c) -> a*b + a*c
						
						Node a = left;
						Node b = right.getLeft();
						Node c = right.getRight();
						
						Node newparentnode = new Node('OR');
						
				        Node newleftnode = new Node('AND');
				        newleftnode.setLeft(a);
				        newleftnode.setRight(b);
				        
				        Node newrightnode = new Node('AND');
				        newrightnode.setLeft(a);
				        newrightnode.setRight(c);
				        
				        newparentnode.setLeft(newleftnode);
				        newparentnode.setRight(newrightnode);
				        
				        
						if (node.getParent()!=null && node.getParent().getLeft()!=null && node.getParent().getLeft()==node) {
							node.getParent().setLeft(newparentnode);
						}
						else {
							node.getParent().setRight(newparentnode);
						}
						
			            distribute(root,newparentnode);
	
					}
				}
				
			 }
		}		
	
	}
	
	
	public class Functionalizer {
	
		/*
		public void main(String[] args) {
			
			// ((um=6) OR (um=7) OR (um=8)) AND ((fbi=11730))
			// ((um=6) OR (um=7) OR (um=8))
			// ((um=6) OR (um=7) OR (um=8)) AND ((fbi=11730) OR (fbo=11730) OR (fse=11730))
			
			String formula1 =  '((um=6) OR (um=7) OR (um=8)) AND ((fbi=11730))';
			String formula2 =  '((um=6) OR (um=7) OR (um=8))';
			String formula3 =  '((um=6) OR (um=7) OR (um=8)) AND ((fbi=11730) OR (fbo=11730) OR (fse=11730))';
					
			System.debug('>>>>>>>>>>>>>>>>>>>>>'+functionalize(formula1));
		}
		*/
		
		//private final static String [] KEYS = {' AND ',' OR ', ' LIKE ', '<>','<=', '>=','<','>','=', '*', '+','/','-'};
		private final String[] KEYS = new String[]{' OR ', ' AND ','='};
		
		private  Map<String,String> KEYS_ALIAS=new Map<String, String>{'='=> 'EQ'};
		//static {
	
			//KEYS_ALIAS.put('<=', 'GTE');
			//KEYS_ALIAS.put('<=', 'LTE');
			//KEYS_ALIAS.put('<', 'LT');
			//KEYS_ALIAS.put('>', 'GT');
			//KEYS_ALIAS.put('>=', 'GTE');
			//KEYS_ALIAS.put('*', 'MULT');
			//KEYS_ALIAS.put('+', 'ADD');
			//KEYS_ALIAS.put('-', 'SUB');
			//KEYS_ALIAS.put('/', 'DIV');
			//KEYS_ALIAS.put('<>', 'OPOSIT');
			//KEYS_ALIAS.put('=', 'EQ');
		//};
	
		
		public String functionalize(String formula) {
			for (String key : KEYS) {
				formula = formula.replaceAll('"', '\''); //formula = formula.replaceAll("\"", "'");
				formula = formula.replaceAll('/\\>\\]/gi,"]"', ']'); //formula.replaceAll("/\\>\\]/gi,']'", "]");
				formula = formula.replaceAll('/\\[\\</gi', '[');	//formula.replaceAll("/\\[\\</gi", "[");			
				while (true) {
					String tmp = functionalizeOnce(key, formula);
					if (tmp.equals(formula)) {
						break;
					}
					formula = tmp;
				}
				
			}
			//return formula;
			return formula.replaceAll(';', ',');
		}
 /*
		private String functionalizeOnce(String key, String formula) {
			formula = formula.replace('\'', '\'');
			String work = hideString(formula);
			Integer operatorPos = work.indexOf(key);
			Integer useless =0;
			if (operatorPos != -1) {
				Integer leftOpPos = getOperator(-1, work, operatorPos);
				String leftOp = (formula.substring(leftOpPos, operatorPos));
				Integer rightOpPos = getOperator(1, work, operatorPos + key.length()) + 1;
				String rightOp = (formula.substring(operatorPos + key.length(),rightOpPos));
				
				if (key.equals('=') && leftOpPos>0) {
					// remove ( ) useless
					String s = formula.substring(leftOpPos-1, leftOpPos);
					String t = formula.substring(rightOpPos,rightOpPos+1);
					
					if (s.equals('(') && t.equals(')')) {
						useless  = 1;
					}
				}
				
				String funcKey = key.trim();
				String alias = KEYS_ALIAS.get(funcKey);
				if (alias != null) {
					funcKey = alias;
				}
				return formula.substring(0, leftOpPos - useless) + funcKey + '(' + leftOp
						+ ',' + rightOp + ')' + formula.substring(rightOpPos + useless);
			}
			return formula;
		}
		*/
		// SPP CHANGES
		private  String functionalizeOnce(String key, String formula) {
			formula = formula.replace('\"', '\'');
			String work = hideString(formula);
			Integer operatorPos = work.indexOf(key);
			Integer useless =0;
			if (operatorPos != -1) {
				Integer leftOpPos = getOperator(-1, work, operatorPos, key);
				String leftOp = (formula.substring(leftOpPos, operatorPos));
				Integer rightOpPos = getOperator(1, work, operatorPos + key.length(),key) + 1;
				String rightOp = (formula.substring(operatorPos + key.length(),rightOpPos));
				
				String funcKey = key.trim();
				String alias = KEYS_ALIAS.get(funcKey);
				if (alias != null) {
					funcKey = alias;
				}
				
				if (key.equals('=') && leftOpPos>0) {
					// remove ( ) useless
					String s = formula.substring(leftOpPos-1, leftOpPos);
					String t = formula.substring(rightOpPos,rightOpPos+1);
					
					if (s.equals('(') && t.equals(')')) {
						useless  = 1;
					}
				}
				
				// case um=10,12,13
				if (key=='=') {
						
					String[] operands = rightOp.split(',');
					if (operands.size()>1) {
						String newform = '';
						Integer c = 0;
						for (Integer i=0;i<operands.size();i++) {
							newform = newform + funcKey + '(' + leftOp + ';' + operands[i] + ')';
							
							c++;
							if (c==2) {
								newform = 'OR(' + newform + ')';
								c=1;
							}
							
							if (i<operands.size()-1) {
								newform = newform + ';';
							}
							
							
						}
						
						return formula.substring(0, leftOpPos - useless) + newform + formula.substring(rightOpPos + useless);
					}
					
				}
				
				
				return formula.substring(0, leftOpPos - useless) + funcKey + '(' + leftOp
						+ ';' + rightOp + ')' + formula.substring(rightOpPos + useless);
			}
			return formula;
		}
		// SPP CHANGES: 26/03/2013
		private Integer getOperator(Integer step, String work, Integer startPos, String key) {
			Integer i = startPos;
			Integer lvl = 0;
			while (true) {
				//System.debug('*************OP:'+work.subString(i,i+1));
				if (work.subString(i,i+1) == ';' && lvl == 0) {//work.charAt(i)
					break;
				}
				if (work.subString(i,i+1) == '(') {
					lvl += step;
				}
				if (work.subString(i,i+1) == ')') {
					lvl -= step;
				}
				if (lvl == -1) {
					break;
				}
				i += step;
				if (i < 0 || i >= work.length()) {
					break;
				}
			}
			return i - step;
		}
 
		
		private String hideString(String s) {
			boolean inString = false;
			String ret = '';
			for (Integer i = 0; i < s.length(); i++) {
				if (s.subString(i,i+1) == '\'') {
					inString = !inString;
				}
				ret += inString && s.subString(i,i+1) != '\'' ? ' ' : s.subString(i,i+1);
			}
			return ret;
		}
	}
	
	
	public class Node {
		private String name;
		private Node parent;
		
		private Node left;
		private Node right;
		
		
		public Node getLeft() {
			return left;
		}
	
		public void setLeft(Node left) {
			this.left = left;
			left.parent = this;
		}
	
		public Node getRight() {
			return right;
		}
	
		public void setRight(Node right) {
			this.right = right;
			right.parent = this;
		}
	
		List<CustomCriteriaSet> crit;
		public List<CustomCriteriaSet> getCrit() {
			return crit;
		}
	
		public void setCrit(List<CustomCriteriaSet> crit) {
			this.crit = crit;
		}
	
		public Node(String pName) {
			name = pName.trim();//.replaceAll('/', '');//pName.trim().replaceAll('/'/gi', '');
		}
	
		
		public String getName() {
			return name;
		}
		
		public Node getParent() {
			return parent;
		}
	}
	
	public class Parser {
		
		public void dump(Node node, Integer lvl) {
			
			if (node!=null) {
			//for (Integer i = 0; i < lvl; i++) {
				//System.debug('-------------->\t');
			//}
			//System.debug('-------------->(' + node.getName());
				dump(node.getLeft(), lvl+1);
				dump(node.getRight(), lvl+1);
			//for (Integer i = 0; i < lvl; i++) {
				//System.debug('-------------->\t');
			//}
			//System.debug('-------------->)');		
			}
		}
		
		public  boolean insideQuotes(String s, Integer pos) {
			boolean insideQuotes = false;
			for (Integer i = 0; i < s.length(); i++) {
				if (s.substring(i,i+1) == '\'') {
					insideQuotes = !insideQuotes;
				}
				if (i == pos) return insideQuotes;
			}
			return false;
		}
		
		public  Node parse(String formula) {
			Node rootNode = new Node('root');
			Integer pos = 0;
			String read = '';
			Node tmp;
			Node current = rootNode ;
	
			while (true) {
				if (formula.substring(pos,pos+1) == '(') {
					if (read.length() > 0) {
						tmp = new Node(read);
						//current.addChild(tmp);
						if (current.getLeft()!=null) {
							current.setRight(tmp);
						}
						else current.setLeft(tmp);
						current = tmp;
						read = '';
					}
	
				} else if (formula.substring(pos,pos+1) == ')') {
					if (read.length() > 0) {
						tmp = new Node(read);
						//current.addChild(tmp);
						current.setRight(tmp);
	
						read = '';
					}
	
					    // the node is full, we can pop
                                if (current.getRight()!=null && current.getLeft()!=null) {
                                        current = current.getParent();
                                }
	
				} else if (formula.substring(pos,pos+1) == ','
						&& insideQuotes(formula, pos) == false) {
					if (read == ' ') {
						read = '';
					} else if (read.length() > 0) {
						tmp = new Node(read);
						//current.addChild(tmp);
						current.setLeft(tmp);
						read = '';
					}
				} else {
					read += formula.substring(pos,pos+1);
				}
				pos++;
				if (pos >= formula.length())
					break;
			}
	
			 return rootNode.getLeft();
		}
	}
		
	static testMethod void testEval()
	{
		Test.startTest();
		
			String formula1 =  '(um=6 OR um=7 OR um=8) AND (fbi=11730 OR fbo=11730 OR fse=11730)';
			String formula2 = '((um=6) OR (um=7) OR (um=8)) AND (fbi=11730)';
			String formula0 = '((um=6) OR (um=7) OR (um=8))';
			String formula3 = 'um=6 AND (um=7 OR um=8)';
			String formula4 = '(um=7 OR um=8) AND um=6';
			String formula5 = 'um=7 OR um=8';
			// ((um=6) OR (um=7) OR (um=8))
			//((um=6) OR (um=7) OR (um=8)) AND ((fbi=11730))
			String formula6 = 'kw=apple';
		 	
		List<CustomCriteriaSet> lc1 = convertToCritSet(formula1);
		System.assertEquals(9,lc1.size(), '9 criteriaSet expected');
		
		System.assert(lc1.get(0).getCriterion().get(0).getParameter() !=null, 'Key expected');
		System.assert(lc1.get(0).getCriterion().get(0).getValue() !=null, 'Value expected');
		System.assertEquals(lc1.get(0).getCriterion().get(0).getOperator() ,'=', 'EQual expected');
		
		List<CustomCriteriaSet> lc2 = convertToCritSet(formula2);
		
		List<CustomCriteriaSet> lc3 = convertToCritSet(formula3);
		
		List<CustomCriteriaSet> lc4 = convertToCritSet(formula6);
		System.assertEquals(1,lc4.size(), ' 1 crit set kw=apple expected');
		
		String f12 = '(((loc=Aberdeen*) OR (loc=Bath*) OR (loc=Belfast*) OR (loc=Birmingham*) OR (loc=Edinburgh*) OR (loc=Glasgow*) OR (loc=London*))) AND (kw=banana OR kw=apple)';
		List<CustomCriteriaSet> lc5 = convertToCritSet(f12);
		System.assertEquals(14,lc5.size(), ' 7OR * 2 of 2OR =14 crit set');
		 
		String f13 ='fruit=apple,banana,black burry';
		List<CustomCriteriaSet> lc6 = convertToCritSet(f13);
		System.debug('>>>>>>>>>>>>LC6:'+lc6);
		
		System.assertEquals(3,lc6.size(), '3 crit set as comma = OR ');
		
		
		String f14 ='(fruit=apple,banana,black burry) AND loc=London';
		List<CustomCriteriaSet> lc7 = convertToCritSet(f14);
		System.debug('>>>>>>>>>>>>LC7:'+lc7);
		System.assertEquals(3,lc7.size(), '3 crit set as comma = OR x 1AND: fruit=apple AND loc=London, fruit=banana AND loc=London, fruit=black burry AND loc=London');
		Test.stopTest();
		
	}
	
	static testMethod void testEval2()
	{
		//String longKV = '((loc=north-london) OR (loc=archway) OR (loc=barnet) OR (loc=crouch-end) OR (loc=east-finchley) OR (loc=edmonton) OR (loc=enfield) OR (loc=finchley) OR (loc=finsbury-park) OR (loc=haringey) OR (loc=highbury) OR (loc=highgate) OR (loc=hornsey) OR (loc=manor-house) OR (loc=muswell-hill) OR (loc=north-finchley) OR (loc=palmers-green) OR (loc=seven-sisters) OR (loc=southgate) OR (loc=tottenham) OR (loc=turnpike-lane) OR (loc=wood-green) OR (loc=north-west-london) OR (loc=colindale) OR (loc=cricklewood) OR (loc=dollis-hill) OR (loc=ealing) OR (loc=edgware) OR (loc=golders-green) OR (loc=greenford) OR (loc=harrow) OR (loc=hendon) OR (loc=kenton) OR (loc=kingsbury) OR (loc=mill-hill) OR (loc=neasden) OR (loc=northolt) OR (loc=pinner) OR (loc=ruislip) OR (loc=stanmore) OR (loc=uxbridge) OR (loc=watford) OR (loc=wembley) OR (loc=wembley-park) OR (loc=willesden) OR (loc=willesden-green)) AND ((pos=bottom))';
		//List<CustomCriteriaSet> lc1 = convertToCritSet(longKV);	
	}
	
	 
}