namespace ManejoPresupuestos.Models
{
    public class ParametroAlterarReceta
    {
        public int ElementoAlterarId { get; set; }
        public string Nombre { get; set; }

        // legacy
        public string Tiempo { get; set; }

        // nuevos
        public int TiempoImpresionMin { get; set; }
        public int TiempoPostMin { get; set; }

        public int ProductoId { get; set; }
        public int LoginId { get; set; }

        // tu código usa int 0/1
        public int Actualizar { get; set; }
        public int Borrar { get; set; }
    }
}
