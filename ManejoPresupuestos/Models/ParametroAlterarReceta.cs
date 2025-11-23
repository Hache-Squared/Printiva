namespace ManejoPresupuestos.Models
{
    public class ParametroAlterarReceta
    {
        public string Nombre { get; set; }
        public string Tiempo { get; set; }
        public int LoginId { get; set; }
        public int ProductoId { get; set; }
        public int ElementoAlterarId { get; set; }
        public int Actualizar { get; set; }
        public int Borrar { get; set; }


    }
}
