namespace ManejoPresupuestos.Models
{
    public class AsignarProductoViewModel
    {
        public int RecetaId { get; set; }
        public int ProductoId { get; set; }

        public string Nombre { get; set; }

        // Legacy (lo dejamos para no romper cosas viejas)
        public string Tiempo { get; set; }

        // Nuevos campos (para NO pisar tiempos a 0 al asignar producto)
        public int TiempoImpresionMin { get; set; }
        public int TiempoPostMin { get; set; }
    }
}